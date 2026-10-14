#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

// Verified QPC V4 source families.
const vec3 source_blue = vec3(0.247059, 0.282353, 0.901961);
const vec3 source_green = vec3(0.035294, 0.690196, 0.000000);
const vec3 source_red = vec3(0.956863, 0.000000, 0.000000);
const vec3 source_orange = vec3(1.000000, 0.482353, 0.000000);
const vec3 source_pink = vec3(1.000000, 0.000000, 0.501961);
const vec3 source_cyan = vec3(0.184314, 0.678431, 1.000000);
const vec3 source_gray = vec3(0.631373, 0.647059, 0.647059);

// Centralized prototype dark-palette targets.
const vec3 dark_main_ink = vec3(0.949020, 0.937255, 0.850980);
const vec3 dark_red = vec3(1.000000, 0.482353, 0.470588);
const vec3 dark_green = vec3(0.458824, 0.847059, 0.603922);
const vec3 dark_blue = vec3(0.470588, 0.658824, 1.000000);
const vec3 dark_cyan = vec3(0.400000, 0.843137, 0.909804);
const vec3 dark_orange = vec3(0.952941, 0.721569, 0.356863);
const vec3 dark_pink = vec3(1.000000, 0.474510, 0.741176);
const vec3 dark_gray = vec3(0.745098, 0.776471, 0.760784);

bool within_family(vec3 color, vec3 source, float tolerance) {
  return distance(color, source) <= tolerance;
}

vec3 remap_palette(vec3 color) {
  float maximum = max(color.r, max(color.g, color.b));
  float minimum = min(color.r, min(color.g, color.b));
  float chroma = maximum - minimum;

  if (maximum <= 0.12 && chroma <= 0.055) {
    return dark_main_ink;
  }
  if (within_family(color, source_red, 0.085)) {
    return dark_red;
  }
  if (within_family(color, source_green, 0.085)) {
    return dark_green;
  }
  if (within_family(color, source_blue, 0.085)) {
    return dark_blue;
  }
  if (within_family(color, source_cyan, 0.085)) {
    return dark_cyan;
  }
  if (within_family(color, source_orange, 0.085)) {
    return dark_orange;
  }
  if (within_family(color, source_pink, 0.085)) {
    return dark_pink;
  }
  if (within_family(color, source_gray, 0.075)) {
    return dark_gray;
  }
  return color;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  vec4 sampled = texture(u_texture, uv);
  if (sampled.a <= 0.0001) {
    frag_color = vec4(0.0);
    return;
  }

  // Flutter image textures are normally premultiplied. The guard also keeps
  // the classification correct if a backend exposes straight-alpha samples.
  float largest_rgb = max(sampled.r, max(sampled.g, sampled.b));
  bool premultiplied = largest_rgb <= sampled.a + 0.001;
  vec3 straight_rgb = premultiplied
      ? clamp(sampled.rgb / sampled.a, 0.0, 1.0)
      : sampled.rgb;
  vec3 remapped = remap_palette(straight_rgb);

  if (all(equal(remapped, straight_rgb))) {
    frag_color = sampled;
    return;
  }

  // Re-premultiply after remapping so coverage and antialiased edges retain
  // the source alpha exactly, with no opaque fringe or color halo.
  frag_color = vec4(remapped * sampled.a, sampled.a);
}
