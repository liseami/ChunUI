//
//  CCVoiceDots.metal
//  ChunUI
//
//  语音面板凹屏的点阵：每粒的亮 / 熄 / 白由 CPU 的 CCVoiceScreen 逐帧写进缓冲，片元只查表。
//  一个像素看自己所在格与八邻，画实心点与亮点外的一圈辉光。开关机的光圈把内容向屏心压扁，中线另叠一道亮线。
//  坐标以 pt 计。经典管线：全屏三角 + setBytes uniforms，输出预乘 alpha。专供 Components/CCVoiceScreenView。
//  [PROTOCOL]: 变更时更新此头部，然后检查 CLAUDE.md
//

#include <metal_stdlib>
using namespace metal;

struct VDOut {
    float4 position [[position]];
    float2 uv;
};

struct VDUniforms {
    float4 tint;
    float2 size;
    float2 origin;
    float pitch;
    float dotSize;
    float glow;
    float glowAlpha;
    float aa;
    float openY;
    float openX;
    float beam;
    uint cols;
    uint rows;
};

vertex VDOut ccVoiceDotsVertex(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    VDOut out;
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    out.uv = float2(p.x, 1.0 - p.y);
    return out;
}

fragment half4 ccVoiceDotsFragment(VDOut in [[stage_in]], constant VDUniforms &u [[buffer(0)]], device const float4 *dots [[buffer(1)]]) {
    float2 p = in.uv * u.size;
    float2 c = u.size * 0.5;
    float2 half_ = c * float2(u.openX, u.openY);
    float3 rgb = float3(0.0);
    float a = 0.0;

    if (abs(p.x - c.x) <= half_.x && abs(p.y - c.y) <= half_.y) {
        float2 q = c + (p - c) / max(float2(u.openX, u.openY), float2(0.001));
        float2 g = (q - u.origin) / u.pitch;
        int2 base = int2(round(g));
        float r = u.dotSize * 0.5;
        for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
                int2 cell = base + int2(dx, dy);
                if (cell.x < 0 || cell.y < 0 || cell.x >= int(u.cols) || cell.y >= int(u.rows)) { continue; }
                float4 d = dots[cell.y * int(u.cols) + cell.x];
                float dist = length(q - (u.origin + float2(cell) * u.pitch));
                float core = 1.0 - smoothstep(r - u.aa * 0.5, r + u.aa * 0.5, dist);
                float fall = 1.0 - smoothstep(0.0, u.glow, dist);
                float halo = d.x * u.glowAlpha * fall * fall;
                float k = core * max(d.x, d.y) + halo * (1.0 - core);
                rgb += mix(u.tint.rgb, float3(1.0), d.z) * k;
                a += k;
            }
        }
    }

    if (u.beam > 0.0 && abs(p.x - c.x) <= half_.x) {
        float dy = (p.y - c.y) / max(u.dotSize, u.aa);
        float k = u.beam * exp(-dy * dy);
        rgb += mix(u.tint.rgb, float3(1.0), 0.5 + 0.5 * u.beam) * k;
        a += k;
    }

    a = min(a, 1.0);
    return half4(half3(min(rgb, float3(a))), half(a));
}
