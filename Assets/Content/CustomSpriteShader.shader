Shader "CustomSpriteShader"
{
    Properties
    {
        // These properties are used in LitInput.hlsl and ShadowCasterPass.hlsl which are included in Shadow Pass.
        [HideInInspector] _MainTex("_MainTex", 2D) = "white" {} // Texture to render.
        [Toggle] _ALPHATEST("Alphatest", Float) = 1 // Whether or not to use alpha as transparency in shadows.
        _Cutoff("Alpha Cutoff", Float) = 0.1 // Where to cutoff the shadow.
        [HideInInspector] _BaseMap ("BaseMap", 2D) = "white" {} // Texture for shadow casting. Can be the same as _MainTex.
        [HideInInspector] _BaseColor ("Base Color", Color) = (0, 0, 0, 1) // Used for alpha cutoff in ShadowCasterPass.hlsl.
    }

    HLSLINCLUDE
    // Import helper methods from Packages/Universal RP.
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    CBUFFER_END
    ENDHLSL

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "OpaqueCutout"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
        }

        Pass
        {
            Name "Render Pass"
            Tags { "LightMode" = "UniversalForward" }
            ZWrite On
            ZTest LEqual
            Cull Off
            Blend Off
            Lighting On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5
            #pragma multi_compile_instancing
            #pragma instancing_options procedural:setup

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
            // Buffers are set via the MaterialPropertyBlock.
            StructuredBuffer<float4x4> _localToWorldBuffer;
#endif

            void setup()
            {
#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
                // Get the transform of the current instance.
                // See https://docs.unity3d.com/6000.0/Documentation/Manual/SL-UnityShaderVariables.html for unity_ObjectToWorld.
                unity_ObjectToWorld = _localToWorldBuffer[unity_InstanceID];
#endif
            }
                        
            Varyings vert(Attributes attributes, uint instanceID : SV_InstanceID)
            {
                Varyings varyings = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(attributes);
                UNITY_TRANSFER_INSTANCE_ID(attributes, varyings);
                // Helper methods can be found at: https://docs.unity3d.com/Packages/com.unity.render-pipelines.core@17.0/manual/built-in-shader-methods.html
                varyings.positionCS = TransformObjectToHClip(attributes.positionOS);
                varyings.uv = attributes.uv;
                return varyings;
            }

            float4 frag(Varyings varyings, uint instanceID : SV_InstanceID) : SV_Target
            {
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, varyings.uv);
                clip(texColor.w - 0.5);
                return texColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Shadow Pass"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
 
            ZWrite On
            ZTest LEqual
 
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x gles
            #pragma target 4.5
 
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
 
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma instancing_options procedural:setup
             
            // These methods are defined in ShadowCasterPass.hlsl.
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
                        
#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
            // Define that same buffers as in Render Pass. This does not duplicate the data.
            StructuredBuffer<float4x4> _localToWorldBuffer;
#endif

            void setup()
            {
#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
                // Get the position again so the shadow is at the correct position.
                unity_ObjectToWorld = _localToWorldBuffer[unity_InstanceID];
#endif
            }

            // You can find the code for these in Packages/Universal RP/Shaders.
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }

    Fallback "Sprites/Default"
}
