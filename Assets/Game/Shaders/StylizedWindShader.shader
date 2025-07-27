Shader "Custom/StylizedWindShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindDirection ("Wind Direction", Vector) = (1,0,0,0)
        _WindSpeed ("Wind Speed", Float) = 1
        _WindStrength ("Wind Strength", Float) = 0.1
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
            };

            float4 _WindDirection;
            float _WindSpeed;
            float _WindStrength;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 worldPos = mul(unity_ObjectToWorld, IN.positionOS).xyz;

                // Wind offset based on world XZ and time
                float windFactor = sin(dot(worldPos.xz, _WindDirection.xz) * 0.2 + _Time.y * _WindSpeed);
                float offset = saturate(IN.positionOS.y) * _WindStrength * windFactor;

                // Apply bending only to upper parts
                float3 bentPos = IN.positionOS.xyz + float3(_WindDirection.x, 0, _WindDirection.z) * offset;

                OUT.positionHCS = TransformObjectToHClip(bentPos);
                OUT.uv = IN.uv;
                return OUT;
            }

            sampler2D _MainTex;

            half4 frag(Varyings IN) : SV_Target
            {
                return tex2D(_MainTex, IN.uv);
            }

            ENDHLSL
        }
    }
}
