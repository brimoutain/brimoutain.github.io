Shader "Unlit/TwoLight"
{
     // Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    
    SubShader
    {
        // Base Pass
        Pass
        {
            // Base Tag
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            // Ԥ����ΪforwardBase
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                // _WorldSpaceLightPos0.xyz�Ǹ�Pass����������ع�Դ��λ�ã�����ù�Դ��ƽ�й⣬��ôw������0��������Դ��w����Ϊ1
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormalDir,worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfLambert = normalize(worldLightDir + viewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormalDir,halfLambert)),_Gloss);
                // Base Pass����ƽ�й⣬ƽ�йⲻ˥��
                fixed atten = 1.0;
                // ��������Base Pass�м�����һ�Σ�����Additional Pass�Ͳ����ټ��㻷����
                // ���Ƶ�ֻ����һ�εĹ��ջ����Է���
                return fixed4(ambient + (diffuse + specular) * atten ,1.0);
            }
            
            ENDCG
        }
        // Additional Pass
        Pass
        {
            //Additional Tag
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                // ��֧�жϴ������Բ�ͬ���͹��ս��в�ͬ��֧��Shader���㴦��
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfLambert = normalize(worldLightDir + viewDir);

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormalDir,worldLightDir));
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormalDir,halfLambert)),_Gloss);

                // ����ͬ��Դ��˥��
                // ƽ�йⲻ˥��
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
                #else
                    #if defined (POINT)
                    // �ѵ�����ת�������Դ������ռ��У�_LightMatrix0������������󴫵ݵ�shader�У���������˶Ե��Դ��Χ�ļ��㣬����ɲο�Unity����Դ�롣����_LightMatrix0�任���ڵ��Դ���Ĵ�lightCoordΪ(0, 0, 0)���ڵ��Դ�ķ�Χ��Ե��lightCoordģΪ1
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    // ʹ�õ㵽��Դ���ľ����ƽ��dot(lightCoord, lightCoord)���ɶ�ά�������꣬��˥������_LightTexture0������_LightTexture0������峤ʲô�����Կ����������
                    // UNITY_ATTEN_CHANNEL��˥��ֵ���ڵ�����ͨ�������������õ�HLSLSupport.cginc�ļ��в鿴��һ��PC������ƽ̨�Ļ�UNITY_ATTEN_CHANNEL��rͨ�����ƶ�ƽ̨�Ļ���aͨ��
                    // ����˵���Ǹ��ݹ�Դ��������ŷ�Ͼ������˥���������
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #elif defined (SPOT)
                    // �ѵ�����ת�����۹�Ƶ�����ռ��У�_LightMatrix0������������󴫵ݵ�shader�У�����������˶Ծ۹�Ƶķ�Χ���Ƕȵļ��㣬����ɲο�Unity����Դ�롣����_LightMatrix0�任���ھ۹�ƹ�Դ���Ĵ���۹�Ʒ�Χ���lightCoordΪ(0, 0, 0)���ڵ��Դ�ķ�Χ��Ե��lightCoordģΪ1
                    float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                    // ����Դ��ͬ�����ھ۹���и���ĽǶȵ�Ҫ�����Ϊ�˵õ�˥��ֵ��������Ҫ��˥����������⣬����Ҫ�Ծ۹�Ƶķ�Χ���ŽǺͷ�������ж�
                    // ��ʱ˥������洢����_LightTextureB0�У���������͵��Դ�е�_LightTexture0�ǵȼ۵�
                    // �۹�Ƶ�_LightTexture0�洢�Ĳ����ǻ��ھ����˥����������һ�Ż����ŽǷ�Χ��˥������
                    // (lightCoord.z > 0)ָ���Ƕ��㷽���ڹ�׶������ĵ㣨�����򲻱�����)
                    // lightCoord.xy / lightCoord.w + 0.5ͨ������w�����������ͶӰ�任(��γ���)��ֵ��Ϊ[-0.5,0.5]��+0.5����Ի��ھ����˥��������й�һ������
                    // �ٸ��ݹ�Դ��������ŷ�Ͼ�����л����Ž������˥���������
                    fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #else
                    fixed atten = 1.0;
                #endif
                #endif

				return fixed4((diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }
    }
	FallBack "Specular"


}
