Shader "Unlit/Blend"
{
    Properties
  {
    _Color("Color Tint",Color) = (1,1,1,1)
    _MainTex("Main Tex",2D) = "white" {}
    _AlphaScale("AlphaScale",Range(0,1)) = 1 
  }
  SubShader
  {
    Tags{"Queue" = "Transparent" "IgnoreProject" = "true" "RenderType" = "Transparent"}
    Pass
    {
      Tags{"LightMode" = "ForwardBase"}
      // �ر����д�룬���û��ģʽ������Դ�������SrcFactorΪԴ͸����SrcAlpha
      // Ŀ��������DstFactor Ϊ 1-SrcAlpha
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
        float3 normal : NORMAL;
        float3 texcoord : TEXCOORD0;
      };

      struct v2f
      {
        float4 pos:SV_POSITION;
        float3 worldPos : TEXCOORD0;
        float3 worldNormal : TEXCOORD1;
        float2 uv : TEXCOORD2;
      };

      v2f vert(a2v v)
      {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
        o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
        return o;
      }

      fixed4 frag(v2f i):SV_Target
      {
        fixed3 worldNormalDir = normalize(i.worldNormal);
        fixed3 worldLighrDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

        fixed4 texColor = tex2D(_MainTex,i.uv);
        fixed3 albedo = texColor.xyz * _Color.rgb;
        fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.xyz;

        fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLighrDir));

        // �˴������в�ͬ���Ҷ����յ����͸���ȼ��˸��жϣ�ʹ��͸����scale����͸����������������
        fixed finalAlpha = texColor.a;
        if(texColor.a < 1)
        {
           finalAlpha = texColor.a * _AlphaScale;
        }
        // ���ʱע��alphaͨ�����м���
        return fixed4(ambient + diffuse,finalAlpha);
      }
      ENDCG
    }
  }

}
