#define SMEAR_DURATION 0.18
#define SMEAR_THICKNESS 0.62
#define SMEAR_OPACITY 0.85

float sdSegment(in vec2 p, in vec2 a, in vec2 b, in float r) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// iCurrentCursor.xy is the -X,+Y corner; .zw is width,height.
vec2 cursorCenter(in vec4 c) {
    return vec2(c.x + c.z * 0.5, c.y - c.w * 0.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 scene = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = scene;

    if (iCurrentCursor.z <= 0.0 || iPreviousCursor.z <= 0.0) return;

    float age = iTime - iTimeCursorChange;
    if (age < 0.0 || age > SMEAR_DURATION) return;

    vec2 head = cursorCenter(iCurrentCursor);
    vec2 tailStart = cursorCenter(iPreviousCursor);
    if (length(head - tailStart) < 1.0) return;

    float t = clamp(age / SMEAR_DURATION, 0.0, 1.0);
    float ease = 1.0 - pow(1.0 - t, 3.0);

    vec2 tail = mix(tailStart, head, ease);
    float radius = min(iCurrentCursor.z, iCurrentCursor.w) * 0.5 * SMEAR_THICKNESS;

    float d = sdSegment(fragCoord, tail, head, radius);
    float mask = 1.0 - smoothstep(0.0, 1.5, d);
    float alpha = mask * (1.0 - ease) * SMEAR_OPACITY;

    fragColor = mix(scene, vec4(iCurrentCursorColor.rgb, 1.0), alpha);
}
