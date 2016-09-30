texture TerrainTypesTexture;
texture EarthTexture;
texture SandTexture;
texture StoneTexture;
float4x4 ModelViewProjection;
float TextureScale;
float2 TerrainSize;

sampler terrainTypesSampler = sampler_state
{
   Texture = (TerrainTypesTexture);
   MipFilter = POINT;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
};

sampler earthSampler = sampler_state
{
   Texture = (EarthTexture);
   MipFilter = POINT;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
};

sampler sandSampler = sampler_state
{
   Texture = (SandTexture);
   MipFilter = POINT;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
};

sampler stoneSampler = sampler_state
{
   Texture = (StoneTexture);
   MipFilter = POINT;
   MinFilter = LINEAR;
   MagFilter = LINEAR;
};

struct VertexShaderInput
{
   float3 position : SV_Position0;
   float2 texCoord : TEXCOORD0;
};

struct VertexShaderOutput
{
   float4 position : SV_Position0;
   float2 texCoordTerrain : TEXCOORD0;
   float2 texCoordPos : TEXCOORD1;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
   VertexShaderOutput output;
   float4 pos = mul(float4(input.position, 1), ModelViewProjection);
   output.position = pos;
   output.texCoordTerrain = input.texCoord;
   output.texCoordPos = input.position.xy * TextureScale;
   return output;
}

float3 blur(float2 coords)
{
    float4 acc = float4(0,0,0,0);
    for(int dx = -1; dx <= 1; dx++)
    {
        for(int dy = -1; dy <= 1; dy++)
        {
            float2 d = float2(dx, dy) / TerrainSize;
            float4 c = tex2D(terrainTypesSampler, coords + d);
            c /= (dx*dx+dy*dy)+1;
            c.a = 1;
            acc += c;
        }
    }
    return acc.rgb / acc.a;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
   float3 typeWeights = tex2D(terrainTypesSampler, input.texCoordTerrain).rgb;//blur(input.texCoordTerrain);

   typeWeights += 0.01;

   float edge = clamp(pow(1.35 - length(typeWeights), 3), 0, 0.8);
   //edge = saturate(sign(edge - 0.78));


   typeWeights = pow(typeWeights, 32);

   typeWeights /= typeWeights.x + typeWeights.y + typeWeights.z;

   float4 color = float4(0, 0, 0, 1);

   color += typeWeights.x * tex2D(earthSampler, input.texCoordPos);
   color += typeWeights.y * tex2D(sandSampler, input.texCoordPos);
   color += typeWeights.z * tex2D(stoneSampler, input.texCoordPos);

   color.rgb = color.rgb * (1-edge);

   return color;
}

technique Technique1
{
   pass Pass1
   {
      // TODO: set renderstates here.

      VertexShader = compile vs_2_0 VertexShaderFunction();
      PixelShader = compile ps_2_0 PixelShaderFunction();
   }
}
