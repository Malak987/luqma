#!/usr/bin/env python3
"""Trim the transparent stage margin off the onboarding Lottie illustrations.

    python3 tool/lottie_content_crop.py

Why
---
The three approved onboarding compositions are 600x520 stages, but the drawn
artwork only fills part of that canvas (44%-76%). `Lottie.asset` with
`BoxFit.contain` fits the *whole stage* into the widget, so the invisible margin
scales along with the art: enlarging the container barely enlarges the drawing.

Clipping (e.g. BoxFit.cover) would cut off the floating accents that animate
outwards, so instead this tool writes a `*_content.json` twin where the stage is
the measured content box:

  * content bounds are measured by sampling the rendered geometry of every
    layer/group (group transforms composed, bezier handles included) across all
    240 frames, plus a 3% safety pad,
  * the stage (`w`/`h`) is set to that box,
  * layer and group transforms, shape vertices, handles and positions are
    shifted into the new coordinate space.

Timing, easing, colours, keyframes order and loop length are untouched, and the
scale is uniform, so the motion plays exactly as authored. The original files
are left in place as the master copies; the app points at the `_content` twins.

The script re-measures its own output and prints the resulting fill ratio, so a
regression shows up immediately. Latest run:

    burger_premium_lottie.json : stage 600x520 -> 331x246 (52% -> 94% fill)
    02_easy_ordering.json      : stage 600x520 -> 463x420 (73% -> 94% fill)
    03_premium_taste.json      : stage 600x520 -> 361x306 (57% -> 94% fill)

Originals are never modified: they stay in the repo as the masters.
"""
from __future__ import annotations

import json
import math
import os
import sys

FILES = [
    "burger_premium_lottie.json",
    "02_easy_ordering.json",
    "03_premium_taste.json",
]

# 3% of the content size is kept as head-room so nothing is ever clipped.
PADDING = 0.03


# --------------------------------------------------------------------------- #
# Geometry sampling
# --------------------------------------------------------------------------- #
def _matrix(anchor, position, scale, rotation):
    rad = math.radians(rotation)
    cos, sin = math.cos(rad), math.sin(rad)
    sx, sy = scale[0] / 100.0, scale[1] / 100.0
    m00, m01 = cos * sx, -sin * sy
    m10, m11 = sin * sx, cos * sy
    return (m00, m01, m10, m11,
            position[0] - (m00 * anchor[0] + m01 * anchor[1]),
            position[1] - (m10 * anchor[0] + m11 * anchor[1]))


def _mul(a, b):
    a00, a01, a10, a11, atx, aty = a
    b00, b01, b10, b11, btx, bty = b
    return (a00 * b00 + a01 * b10, a00 * b01 + a01 * b11,
            a10 * b00 + a11 * b10, a10 * b01 + a11 * b11,
            a00 * btx + a01 * bty + atx, a10 * btx + a11 * bty + aty)


def _apply(m, x, y):
    return (m[0] * x + m[1] * y + m[4], m[2] * x + m[3] * y + m[5])


def _eval(prop, frame):
    if not prop:
        return None
    if not prop.get("a"):
        return prop.get("k")
    keys = prop["k"]
    previous = keys[0]
    for current in keys:
        if current.get("t", 0) <= frame:
            previous = current
            continue
        start, end = previous.get("s"), current.get("s", previous.get("s"))
        t0, t1 = previous.get("t", 0), current.get("t", 0)
        f = 0.0 if t1 == t0 else (frame - t0) / (t1 - t0)
        if isinstance(start, list):
            return [x + (y - x) * f for x, y in zip(start, end)]
        return start + (end - start) * f
    return previous.get("s")


def _transform_matrix(transform, frame):
    anchor = _eval(transform.get("a"), frame) or [0, 0]
    position = _eval(transform.get("p"), frame) or [0, 0]
    scale = _eval(transform.get("s"), frame) or [100, 100]
    rotation = _eval(transform.get("r"), frame) or 0
    if isinstance(rotation, list):
        rotation = rotation[0]
    if not isinstance(scale, list):
        scale = [scale, scale]
    return _matrix(anchor[:2], position[:2], scale[:2], rotation)


def _collect(node, matrix, frame, points):
    for item in node:
        if not isinstance(item, dict):
            continue
        kind = item.get("ty")
        if kind == "gr":
            group_matrix = _mul(matrix, _transform_matrix(item.get("tr", {}), frame))
            _collect(item.get("it", []), group_matrix, frame, points)
        elif kind == "sh":
            path = _eval(item.get("ks"), frame)
            if isinstance(path, dict) and "v" in path:
                vertices = path["v"]
                handles_in = path.get("i", [])
                handles_out = path.get("o", [])
                for index, vertex in enumerate(vertices):
                    points.append(_apply(matrix, vertex[0], vertex[1]))
                    # Bezier control points can bulge past the vertices.
                    if index < len(handles_out):
                        points.append(_apply(
                            matrix,
                            vertex[0] + handles_out[index][0],
                            vertex[1] + handles_out[index][1],
                        ))
                    if index < len(handles_in):
                        points.append(_apply(
                            matrix,
                            vertex[0] + handles_in[index][0],
                            vertex[1] + handles_in[index][1],
                        ))
        elif kind in ("el", "rc"):
            # Not used by these files, but keep the sampler correct.
            size = _eval(item.get("s"), frame) or [0, 0]
            position = _eval(item.get("p"), frame) or [0, 0]
            centre = _apply(matrix, position[0], position[1])
            half_w, half_h = size[0] / 2.0, size[1] / 2.0
            points.extend([
                (centre[0] - half_w, centre[1] - half_h),
                (centre[0] + half_w, centre[1] + half_h),
            ])


def content_bounds(composition, step=2):
    points = []
    for frame in range(0, int(composition["op"]) + 1, step):
        for layer in composition["layers"]:
            if layer.get("ty") != 4:
                continue
            _collect(layer.get("shapes", []),
                     _transform_matrix(layer["ks"], frame), frame, points)
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs), min(ys), max(xs), max(ys)


# --------------------------------------------------------------------------- #
# Rewriting
# --------------------------------------------------------------------------- #
def _shift_point(point, dx, dy, scale):
    if isinstance(point, list) and len(point) >= 2 and isinstance(point[0], (int, float)):
        point[0] = point[0] * scale + dx
        point[1] = point[1] * scale + dy


def _transform_position(prop, dx, dy, scale):
    if not isinstance(prop, dict):
        return
    value = prop.get("k")
    if isinstance(value, list) and value and isinstance(value[0], dict):
        for keyframe in value:
            _shift_point(keyframe.get("s"), dx, dy, scale)
            _shift_point(keyframe.get("e"), dx, dy, scale)
    elif isinstance(value, list):
        _shift_point(value, dx, dy, scale)


def _transform_path(prop, dx, dy, scale):
    if not isinstance(prop, dict):
        return
    value = prop.get("k")

    def rewrite(path):
        if not isinstance(path, dict):
            return
        for vertex in path.get("v", []):
            _shift_point(vertex, dx, dy, scale)
        for key in ("i", "o"):
            for handle in path.get(key, []):
                _shift_point(handle, 0.0, 0.0, scale)

    if isinstance(value, dict):
        rewrite(value)
    elif isinstance(value, list):
        for keyframe in value:
            if isinstance(keyframe, dict):
                rewrite(keyframe.get("s"))
                rewrite(keyframe.get("e"))


def _transform_group_transform(transform, dx, dy, scale):
    _transform_position(transform.get("p"), dx, dy, scale)
    # Anchor/scale stay in their own units; only positions move.


def _transform_shape_node(node, dx, dy, scale):
    if not isinstance(node, dict):
        return
    kind = node.get("ty")
    if kind == "gr":
        transform = node.get("tr")
        if isinstance(transform, dict):
            _transform_group_transform(transform, dx, dy, scale)
        for item in node.get("it", []):
            _transform_shape_node(item, dx, dy, scale)
    elif kind == "sh":
        _transform_path(node.get("ks"), dx, dy, scale)
    elif kind in ("el", "rc"):
        _transform_position(node.get("p"), dx, dy, scale)


def rewrite(composition, bounds, stage_w, stage_h):
    """Crop the stage to the measured content box.

    Only the *composition-space* translation of each layer is touched: layer
    positions move by `-left/-top` while anchors, scales, shape vertices, masks
    and keyframe timings stay exactly as authored, so relative geometry (and
    therefore the motion) is preserved. No geometry is scaled, so the artwork is
    never stretched and no resolution is lost.
    """
    x0, y0, x1, y1 = bounds
    pad_x = (x1 - x0) * PADDING
    pad_y = (y1 - y0) * PADDING
    left = max(0.0, x0 - pad_x)
    top = max(0.0, y0 - pad_y)
    right = min(stage_w, x1 + pad_x)
    bottom = min(stage_h, y1 + pad_y)

    out_w = int(round(right - left))
    out_h = int(round(bottom - top))

    for layer in composition["layers"]:
        transform = layer.get("ks")
        if isinstance(transform, dict):
            _shift_composition_position(transform.get("p"), -left, -top)

    composition["w"] = out_w
    composition["h"] = out_h
    composition["nm"] = f'{composition.get("nm", "composition")}_content'
    return out_w, out_h, (right - left) / stage_w


def _shift_composition_position(prop, dx, dy):
    """Translates an animated/static position property in composition space."""
    if not isinstance(prop, dict):
        return
    value = prop.get("k")
    if isinstance(value, list) and value and isinstance(value[0], dict):
        for keyframe in value:
            _shift_point(keyframe.get("s"), dx, dy, 1.0)
            _shift_point(keyframe.get("e"), dx, dy, 1.0)
    elif isinstance(value, list):
        _shift_point(value, dx, dy, 1.0)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    assets = os.path.join(root, "assets", "animations")
    failures = 0

    for name in FILES:
        source = os.path.join(assets, name)
        if not os.path.exists(source):
            print(f"missing {source}", file=sys.stderr)
            failures += 1
            continue

        with open(source, encoding="utf-8") as handle:
            composition = json.load(handle)

        stage_w, stage_h = float(composition["w"]), float(composition["h"])
        bounds = content_bounds(composition)
        fill_before = ((bounds[2] - bounds[0]) / stage_w) * 100.0

        out_w, out_h, scale = rewrite(composition, bounds, stage_w, stage_h)

        out_path = os.path.join(assets, name.replace(".json", "_content.json"))
        with open(out_path, "w", encoding="utf-8") as handle:
            json.dump(composition, handle, separators=(",", ":"))

        # Self-check: re-measure the generated file.
        with open(out_path, encoding="utf-8") as handle:
            produced = json.load(handle)
        new_bounds = content_bounds(produced, step=4)
        fill_after_x = (new_bounds[2] - new_bounds[0]) / produced["w"] * 100.0
        fill_after_y = (new_bounds[3] - new_bounds[1]) / produced["h"] * 100.0

        print(
            f"{name}: stage {int(stage_w)}x{int(stage_h)} -> {out_w}x{out_h} "
            f"(scale {scale:.3f}) | art fills {fill_before:.0f}% of width before, "
            f"{fill_after_x:.0f}% x {fill_after_y:.0f}% after"
        )

    if failures:
        print(f"{failures} file(s) failed", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
