Shader "Meitu/Matcap_Skin" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex("Albedo Tex", 2D) = "white" {}
		_SSSTex("SSS Tex", 2D) = "white" {}
		_BumpMap ("Normal Tex", 2D) = "bump" {}
		_BumpValue ("Normal Value", Range(0,10)) = 1				
		_MatCapDiffuse ("MatCapDiffuse (RGB)", 2D) = "white" {}
		_MatCapSubMask ("MatCapSubMask", 2D) = "white" {}
		_SSSValue ("SSS Value", Range(0,1)) = 1
		_MatCapSpec ("Matcap Spec(Alpha As Reflect)", 2D) = "black"{}
		_MatCapSpecValue ("Matcap Spec Value", Range(0,1)) = 0
		_ReflectMask("Reflect Mask",2D)="Black"{}	
		_ReflectStrengh("ReflectStrengh",Range(0,1))=0.2
	}
	
	Subshader {
		Tags { "RenderType"="Opaque" }
		
		Pass {
			Tags { "LightMode" = "Always" }
			
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityCG.cginc"
				
				struct v2f { 
					float4 pos : SV_POSITION;
					float4	uv : TEXCOORD0;
					float3	TtoV0 : TEXCOORD1;
					float3	TtoV1 : TEXCOORD2;
					float2	NtoV : TEXCOORD3;
				};

				uniform float4 _MainTex_ST;
				
				v2f vert (appdata_tan v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos (v.vertex);
					o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

					o.NtoV.x = dot(normalize(UNITY_MATRIX_IT_MV[0]), v.normal);
					o.NtoV.y = dot(normalize(UNITY_MATRIX_IT_MV[1]), v.normal);
					
					TANGENT_SPACE_ROTATION;
					o.TtoV0 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[0].xyz));
					o.TtoV1 = normalize(mul(rotation, UNITY_MATRIX_IT_MV[1].xyz));
					return o;
				}
				
				uniform fixed4 _Color;
				uniform sampler2D _BumpMap;
				uniform sampler2D _MatCapDiffuse;
				uniform sampler2D _MatCapSubMask;
				uniform sampler2D _MatCapSpec;
				uniform sampler2D _MainTex;
				uniform sampler2D _SSSTex;
				uniform fixed _BumpValue;
				uniform fixed _SSSValue;
				uniform fixed _MatCapSpecValue;
				uniform sampler2D _ReflectMask;
				uniform fixed _ReflectStrengh;
				
				float4 frag (v2f i) : COLOR
				{
					fixed4 c = tex2D(_MainTex, i.uv.xy);
					fixed4 sss = tex2D(_SSSTex, i.uv.xy);
					fixed Reflection = tex2D(_ReflectMask,i.uv.xy).r * _ReflectStrengh;
					float3 normal = UnpackNormal(tex2D(_BumpMap, i.uv.xy));
					normal.xy *= _BumpValue;
					normal.z = sqrt(1.0- saturate(dot(normal.xy ,normal.xy)));
					
					half2 vn;
					vn.x = dot(i.TtoV0, normal);
					vn.y = dot(i.TtoV1, normal);

					fixed4 Matcapcol = tex2D(_MatCapDiffuse, vn * 0.5 + 0.5);			
					fixed4 Sub = tex2D(_MatCapSubMask, i.NtoV * 0.5 + 0.5) * _SSSValue;	
					fixed4 matcapSpec = tex2D(_MatCapSpec, vn * 0.5 + 0.5) * _MatCapSpecValue;
					fixed4 matcapSpec2 = matcapSpec.a *5* Reflection;					
					fixed4 finalColor =lerp( Matcapcol * c, sss , Sub )*_Color + matcapSpec+ matcapSpec2;
					return finalColor;
				}

			ENDCG
		}
	}
	Fallback "VertexLit"
}