// Water flow shader for river
// Shows animated flow with varying speed and water clarity

uniform float time;           // Time for animation
uniform vec2 flowDirection;   // Direction of flow (normalized)
uniform float flowSpeed;      // Speed multiplier for flow
uniform vec3 waterColor;      // Base water color
uniform float clarity;        // Water clarity (0 = muddy, 1 = clear)

// Simple noise function
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Smooth noise
float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Flowing noise pattern with multiple random directions
float flowNoise(vec2 uv, float time) {
    // Create multiple flowing patterns in different random directions
    // This creates chaotic, turbulent flow
    vec2 flow1 = vec2(0.3, 0.8) * time * flowSpeed;
    vec2 flow2 = vec2(-0.5, 0.6) * time * flowSpeed * 0.7;
    vec2 flow3 = vec2(0.7, 0.4) * time * flowSpeed * 0.5;

    float n1 = smoothNoise((uv + flow1) * 2.5);
    float n2 = smoothNoise((uv + flow2) * 5.0) * 0.5;
    float n3 = smoothNoise((uv + flow3) * 10.0) * 0.25;

    return n1 + n2 + n3;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Get base texture color
    vec4 texColor = Texel(texture, texture_coords);

    // Use screen coordinates for continuous noise across polygons
    vec2 worldPos = screen_coords * 0.01; // Scale down for reasonable noise frequency

    // Calculate flow pattern
    float flow = flowNoise(worldPos, time);

    // Add ripples perpendicular to flow
    vec2 perpFlow = vec2(-flowDirection.y, flowDirection.x);
    float ripple = sin((worldPos.x * perpFlow.x + worldPos.y * perpFlow.y) * 2.0 + time * flowSpeed * 2.0) * 0.5 + 0.5;
    ripple = ripple * 0.3; // Reduce ripple intensity

    // Combine flow and ripples
    float wave = flow * 0.7 + ripple * 0.3;

    // Calculate water color based on clarity
    // Clear water: brown with slight green tint
    // Muddy water: darker brown
    vec3 clearWater = vec3(0.42, 0.32, 0.20);     // Brown with slight green
    vec3 muddyWater = vec3(0.48, 0.35, 0.22);     // Darker muddy brown
    vec3 baseWaterColor = mix(muddyWater, clearWater, clarity);

    // Make flow visible by modulating the color based on wave pattern
    // Creates darker and lighter streaks showing turbulent flow
    float flowPattern = wave * 0.4 - 0.2; // Range from -0.2 to 0.2
    vec3 resultColor = baseWaterColor + vec3(flowPattern * 0.15);

    // Add subtle noise for texture variation
    float textureNoise = noise(worldPos * 8.0 + time * 1.5) * 0.06;
    resultColor += vec3(textureNoise - 0.03); // Center around 0

    // Apply color and original alpha
    return vec4(resultColor * color.rgb * waterColor, texColor.a * color.a);
}
