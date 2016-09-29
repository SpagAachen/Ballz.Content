texture TerrainTypesTexture;
texture EarthTexture;
texture SandTexture;
texture StoneTexture;
float4x4 ModelViewProjection;
float TextureScale;

sampler terrainTypesSampler = sampler_state
{
   Texture = (TerrainTypesTexture);
   MipFilter = POINT;
   MinFilter = POINT;
   MagFilter = POINT;
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

float3 filterTerrainType(float2 texcoord, float2 texscale)
{
    float fx = frac(texcoord.x);
    float fy = frac(texcoord.y);
    texcoord.x -= fx;
    texcoord.y -= fy;

    float4 p = float4(texcoord.x - 0.5, texcoord.x + 0.5, texcoord.y - 0.5, texcoord.y + 0.5);
    p = p * float4(texscale.x, texscale.x, texscale.y, texscale.y);

    float type = 0;

    float type0 = tex2D(terrainTypesSampler, float2(p.x, p.z)).r * 255.0;
    float3 typeWeights0 = saturate(1 - abs(float3(1, 2, 3) - type0));


    float type1 = tex2D(terrainTypesSampler, float2(p.y, p.z)).r * 255.0;
    float3 typeWeights1 = saturate(1 - abs(float3(1, 2, 3) - type1));

    float type2 = tex2D(terrainTypesSampler, float2(p.x, p.w)).r * 255.0;
    float3 typeWeights2 = saturate(1 - abs(float3(1, 2, 3) - type2));

    float type3 = tex2D(terrainTypesSampler, float2(p.y, p.w)).r * 255.0;
    float3 typeWeights3 = saturate(1 - abs(float3(1, 2, 3) - type3));

    float3 typeWeights = lerp(
        lerp(typeWeights0, typeWeights1, fx),
        lerp(typeWeights2, typeWeights3, fx), fy);

    typeWeights = pow(typeWeights, 32);

    typeWeights = typeWeights / (typeWeights.x + typeWeights.y + typeWeights.z);

    return typeWeights;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
   float2 texSize = float2(500, 500);
   float2 typeCoords = float2(input.texCoordTerrain.y*0.5, input.texCoordTerrain.x);
   float3 typeWeights = filterTerrainType(typeCoords*texSize,  1.0 / texSize);

   float4 color = float4(0, 0, 0, 1);

   color += typeWeights.x * tex2D(earthSampler, input.texCoordPos);
   color += typeWeights.y * tex2D(sandSampler, input.texCoordPos);
   color += typeWeights.z * tex2D(stoneSampler, input.texCoordPos);

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
