Shader "Custom/StylizedWindShader" {
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindDirection ("Wind Direction", Vector) = (1,0,0,0)
        _WindSpeed ("Wind Speed", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.1
        _WaveMode ("Wave Mode (0=xz,1=y,2=xyz)", Float) = 0
        
        [Header(Hover Effect Debug)]
        _ShowHoverArea ("Show Hover Area", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float hoverEffect : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _WindDirection;
                float _WindSpeed;
                float _WindStrength;
                float _WaveMode;
                float _ShowHoverArea;
            CBUFFER_END

            // Global properties set by script
            float4 _HoverPosition;
            float _HoverStrength;
            float _HoverRadius;

            sampler2D _MainTex;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 bendDir = float3(0, 0, 0);

                // === WIND WAVE EFFECTS ===
                float windWave = 0;

                if (_WaveMode < 0.5) // XZ plane wave
                {
                    windWave = sin(dot(worldPos.xz, _WindDirection.xz) * 0.2 + _Time.y * _WindSpeed);
                    bendDir += float3((_WindDirection.x * windWave), 0, (_WindDirection.z * windWave)) * _WindStrength;
                }
                else if (_WaveMode < 1.5) // Y-based wave
                {
                    windWave = sin(worldPos.y * 5 + _Time.y * _WindSpeed);
                    bendDir += float3(windWave, 0, 0) * _WindStrength;
                }
                else // XYZ combined wave
                {
                    windWave = sin((worldPos.x + worldPos.y + worldPos.z) * 0.4 + _Time.y * _WindSpeed);
                    bendDir += float3(0.3, 0, 1) * windWave * _WindStrength;
                }

                // === HOVER EFFECT ===
                float dist = distance(worldPos, _HoverPosition.xyz);
                float hoverEffect = 0;
                
                if (_HoverPosition.x < 9000 && dist < _HoverRadius) 
                {
                    hoverEffect = saturate(1.0 - dist / _HoverRadius);
                    
                    // Multiple hover effects for dramatic movement:
                    
                    // 1. Push away from hover point (radial)
                    float3 hoverDir = normalize(worldPos - _HoverPosition.xyz);
                    bendDir += hoverDir * hoverEffect * _HoverStrength * 0.5;
                    
                    // 2. Push up for visibility
                    bendDir += float3(0, 1, 0) * hoverEffect * _HoverStrength * 0.3;
                    
                    // 3. Add circular motion for more dynamic effect
                    bendDir += float3(sin(hoverEffect * 3.14159), 0, cos(hoverEffect * 3.14159)) * hoverEffect * _HoverStrength * 0.2;
                }

                // === APPLY BENDING ===
                // Use vertex height to make taller parts bend more (like real grass/cloth)
                float heightMultiplier = saturate(IN.positionOS.y + 0.5); // Adjust +0.5 based on your mesh
                float3 windBend = bendDir * _WindStrength * heightMultiplier;
                float3 finalPos = IN.positionOS.xyz + windBend;


                OUT.positionHCS = TransformObjectToHClip(finalPos);
                OUT.uv = IN.uv;
                OUT.worldPos = worldPos;
                OUT.hoverEffect = hoverEffect;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 baseColor = tex2D(_MainTex, IN.uv);
                
                // Optional: Show hover area for debugging
                if (_ShowHoverArea > 0.5 && IN.hoverEffect > 0.01)
                {
                    // Blend green to show hover effect area
                    return lerp(baseColor, half4(0, 1, 0, 1), IN.hoverEffect * 0.3);
                }
                
                return baseColor;
            }

            ENDHLSL
        }
    }
}