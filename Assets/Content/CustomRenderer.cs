using UnityEngine;

[ExecuteAlways]
public class CustomRenderer : MonoBehaviour
{
    /// <summary>
    /// The light the will be used for casting shadows.
    /// </summary>
    public Light directionalLight;

    /// <summary>
    /// Base material for rendering.
    /// </summary>
    public Material material;

    /// <summary>
    /// Sprite to render.
    /// </summary>
    public Sprite sprite;

    /// <summary>
    /// How many sprites to render.
    /// </summary>
    [Min(1)] public int spriteCount;

    /// <summary>
    /// Simple quad mesh to render the sprite texture.
    /// </summary>
    private Mesh mesh;

    private Mesh ConstructQuad()
    {
        Mesh quad = new();
        quad.name = "Quad";
        quad.vertices = new Vector3[4]
        {
                new(0f, 1f, 0f), //left up
                new(1f, 1f, 0f), //right up
                new(0f, 0f, 0f), //left down
                new(1f, 0f, 0f), //right down
        };
        quad.triangles = new int[6]
        {
                // upper left triangle
                0, 1, 2,
                // down right triangle
                3, 2, 1,
        };
        quad.normals = new Vector3[4]
        {
            -Vector3.forward,
            -Vector3.forward,
            -Vector3.forward,
            -Vector3.forward,
        };
        quad.uv = new Vector2[4]
        {
            new (0f, 1f), //left up
            new (1f, 1f), //right up
            new (0f, 0f), //left down
            new (1f, 0f), //right down
        };
        return quad;
    }

    private bool IsInitialized()
    {
        return directionalLight != null && mesh != null && sprite != null;
    }

    private void OnDestroy()
    {
#if UNITY_EDITOR
        if (!UnityEditor.EditorApplication.isPlaying)
        {
            DestroyImmediate(mesh);
        }
        else
        {
            Destroy(mesh);
        }
#else
        Destroy(mesh);
#endif
    }

    private void Render()
    {
        MaterialPropertyBlock matProps = new();
        // These properties correspond to the "Properties" section in CustomSpriteShader.
        matProps.SetTexture("_MainTex", sprite.texture);
        matProps.SetTexture("_BaseMap", sprite.texture);
        matProps.SetVector("_LightDirection", directionalLight.transform.forward);
        CreateLocalToWorldBuffer(matProps);
        RenderParams renderParams = new(material)
        {
            // The worldBounds refer to the area that is being rendered. This will depend on your application.
            worldBounds = new Bounds(Vector3.zero, 10000 * Vector3.one),
            matProps = matProps,
            shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On,
        };
        Graphics.RenderMeshPrimitives(renderParams, mesh, submeshIndex: 0, instanceCount: spriteCount);
    }

    private void CreateLocalToWorldBuffer(MaterialPropertyBlock matProps)
    {
        ComputeBuffer buffer = new(spriteCount, stride: sizeof(float) * 16);
        Matrix4x4[] positions = new Matrix4x4[spriteCount];
        for (int i = 0; i < spriteCount; i++)
        {
            Vector3 position = new(i / 20, 0, i % 20);
            positions[i] = Matrix4x4.TRS(position, Quaternion.identity, Vector3.one);
        }
        buffer.SetData(positions);
        // The buffer must be defined in every shader pass that it is used in.
        // See CustomSpriteShader Render Pass and Shadow Pass.
        matProps.SetBuffer("_localToWorldBuffer", buffer);
    }

    private void Start()
    {
        mesh = ConstructQuad();
    }

    private void Update()
    {
        if (!IsInitialized())
        {
            return;
        }
        Render();
    }
}