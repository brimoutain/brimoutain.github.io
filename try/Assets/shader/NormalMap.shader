Shader "Unlit/NormalMap"
{
       Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "white"{}
        _BumpMap("NormalMap",2D) = "bump"{}
        _BumpScale("Bump Scale",Float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0,256)) = 20
    }

    SubShader{
        Pass{

            Tags{ "LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //把顶点的切线填进来
                float4 texcoord : TEXCOORD0;
               };

            struct v2f{
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                };

            v2f vert(a2v v){
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);
                TANGENT_SPACE_ROTATION;

                //转到切线方向
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;

                return o;
                }

            fixed4 frag(v2f i): SV_TARGET{
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // tex2D方法获取指定贴图对应像素坐标上的值，一般是颜色值
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                fixed3 tangentNormal;

                // 是对法线采样的反映射函数，也就是tangentNormal = 2 * packedNormal.xyz - 1
                // 将法线从切线贴图上的RGB转为切线空间的法线坐标
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;

                 // 归一化方向向量模长为1，即为(tangentNormal.x)^2 + (tangentNormal.y)^2 + (tangentNormal.z)^2 = 1
                // dot(tangentNormal.xy,tangentNormal.xy) = (x,y) · (x,y) = x^2 + y^2
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,tangentNormal)),_Gloss);

                fixed3 color = ambient + diffuse + specular;

                return fixed4(color,1.0);
                }

            ENDCG
        }
    }
    FallBack "Specular"
}
