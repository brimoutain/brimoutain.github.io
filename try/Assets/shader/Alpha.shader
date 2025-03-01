// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Alpha"
{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {}
        _CutOff("Alpha CutOff",Range(0,1)) = 0.5
    }

    SubShader{

            //��һ������͸���Ȳ��ԣ�������RenderType������Unity��Shader���뵽��ǰ������顪�������˴�ΪTransparentCutout��
            //��͸�����󣺶��ڰ�͸��������˵������ͨ������Ҫ��ӦͶӰ����Ͷ�䣬��ΪͶӰ����Ч�����ܻ��ƻ����ǵİ�͸��Ч����
            //��ˣ���IgnoreProjector����Ϊtrue������Щ������˵�Ƿǳ����õġ�
            //��Ч��һЩ��Ч�����緢���塢����ȣ�Ҳ����Ҫ��Ӧ���������Ͷ����Ӱ��
            //��Ϊ����ͨ�����Լ��Ĺ��պ���ӰЧ������IgnoreProjector����Ϊtrue����ȷ����Щ��Ч���󲻻��ܵ���������Ͷ�����Ӱ��Ӱ��
            Tags{"Queue"="AlphaTest""IgnoreProject"="True""RenderType"="TransparentCutout"}
        Pass{
            Tags{"LightMode"="ForwardBase"}
    
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed3 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _CutOff;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                };

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal: TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;


                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv.xy);

                clip(texColor.a - _CutOff);

                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.xyz;
                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldLightDir,worldNormal));

                return fixed4(ambient+diffuse,1.0);
                }
            ENDCG
    
        }

    }
    Fallback "Transprant/Cutout/VertexLit"
}
