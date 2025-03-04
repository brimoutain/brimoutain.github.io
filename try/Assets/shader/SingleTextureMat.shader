// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SingleTextureMat"
{
    Properties{
	   _Color("Color Tint",Color) = (1,1,1,1)
	   _MainTex("Main Tex",2D) = "white" {}
	   _Specular("Specular",Color) = (1,1,1,1)
	   _Gloss("Gloss",Range(8.0,256)) = 20
	}

	SubShader{

		Pass{
			Tags {"LightMode"="ForwardBase"}
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldPos : TEXTCOORD0;
				float3 worldNormal : TEXTCOORD1;
				float2 uv : TEXTCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldPos = (unity_ObjectToWorld,v.vertex).xyz;

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				return o;
				}

			fixed4 frag(v2f i):SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);

				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir));

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);

				return fixed4(ambient + diffuse + specular,1.0);
				}

			ENDCG
		}
	}
	FallBack "Specular"
}
