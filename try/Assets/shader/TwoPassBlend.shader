Shader "Unlit/TwoPassBlend"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _AlphaScale("Alpha Scale",Range(0,1)) = 1
    }
    SubShader
    {
        Tags{"Queue"="Transparent""IgnoreProjector"="True""RenderType"="TransParent"}

        Pass
        {
            ZWrite On

            ColorMask 0
        }

        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaScale;

             struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNromal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.vertex.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                o.worldNromal = UnityObjectToWorldNormal(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i):SV_TARGET
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.pos));
                fixed3 worldNormal = normalize(i.worldNromal);

                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = _Color.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldLightDir,worldNormal));

                fixed3 color = ambient + diffuse ;
                fixed alpha = _AlphaScale * texColor.a;
                return fixed4(color ,alpha );
                }
            ENDCG
        }
        }
     FallBack "Transparent/VertexLit"
}
