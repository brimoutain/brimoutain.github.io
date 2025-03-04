Shader "Unlit/RampTexture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _RampTex("Ramp Tex",2D) = "white" {}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,255)) = 20
    }
    
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord,_RampTex);
                //o.uv = v.texcoord.xy * _RampTex_ST.xy + _RampTex_ST.zw;
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                //fixed3 worldPos = normalize(i.worldPos);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed haleLambert = 0.5 * dot(worldNormal,worldLightDir) + 0.5;
                // 对漫反射光照应用渐变纹理
                // 使用半兰伯特对漫反射光照根据渐变纹理贴图进行采样颜色值
                // 值域为[0,1],对应纹理贴图最左侧为0，最右侧为1
                // 其实渐变纹理的颜色值只在横轴上变化，因此本质是一维的
                // 只是纹理本身是二维图像，因此我们用一个二维向量进行采样
                fixed3 diffuseColor = tex2D(_RampTex,fixed2(haleLambert,haleLambert)).rgb * _Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * diffuseColor;
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                return  fixed4(diffuse + specular + ambient , 1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Specular"
}

