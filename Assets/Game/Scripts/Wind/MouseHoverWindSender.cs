using UnityEngine;

public class UltimateWindShaderController : MonoBehaviour
{
    [Header("Hover Control")]
    [SerializeField] private LayerMask hoverLayer = -1;
    [SerializeField] private float hoverRadius = 2f;
    [SerializeField] private float hoverStrength = 2f;
    
    [Header("Effect Presets")]
    [SerializeField] private bool usePresets = true;
    [SerializeField] private EffectPreset currentPreset = EffectPreset.ShowcaseAll;
    
    [Header("Manual Effect Control")]
    [SerializeField] private bool manualControl = false;
    [SerializeField] private bool enableFabricStretch = true;
    [SerializeField] private bool enableNoiseVariation = true;
    [SerializeField] private bool enableRimLighting = true;
    [SerializeField] private bool enableWindColorShift = true;
    [SerializeField] private bool enableHoverGlow = true;
    
    [Header("Animation")]
    [SerializeField] private bool animateEffects = false;
    [SerializeField] private float animationSpeed = 1f;
    
    [Header("Debug")]
    [SerializeField] private bool debugMode = false;
    [SerializeField] private bool showGizmos = true;

    public enum EffectPreset
    {
        None = 0,
        FabricStretchOnly = 1,
        NoiseVariationOnly = 2,
        RimLightingOnly = 3,
        WindColorShiftOnly = 4,
        HoverGlowOnly = 5,
        ClassicFlag = 6,
        MagicalBanner = 7,
        ShowcaseAll = 8
    }

    private Camera mainCamera;
    private Material targetMaterial;
    private Vector3 currentHoverPos;
    
    // Shader property IDs
    private static readonly int HoverPosID = Shader.PropertyToID("_HoverPosition");
    private static readonly int HoverStrengthID = Shader.PropertyToID("_HoverStrength");
    private static readonly int HoverRadiusID = Shader.PropertyToID("_HoverRadius");

    private void Start()
    {
        // Find camera
        mainCamera = Camera.main ?? FindObjectOfType<Camera>();
        if (mainCamera == null)
        {
            Debug.LogError("UltimateWindShaderController: No camera found!");
            enabled = false;
            return;
        }

        // Get material from renderer
        Renderer renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            targetMaterial = renderer.material;
        }

        // Initialize shader properties
        Shader.SetGlobalFloat(HoverStrengthID, hoverStrength);
        Shader.SetGlobalFloat(HoverRadiusID, hoverRadius);
        currentHoverPos = new Vector3(9999, 9999, 9999);
        Shader.SetGlobalVector(HoverPosID, currentHoverPos);

        // Apply initial preset
        if (usePresets)
            ApplyPreset(currentPreset);

        if (debugMode)
            Debug.Log($"UltimateWindShaderController initialized with preset: {currentPreset}");
    }

    private void Update()
    {
        if (mainCamera == null) return;

        // Handle hover detection
        UpdateHoverEffect();

        // Handle preset changes
        if (usePresets && !manualControl)
            ApplyPreset(currentPreset);
        else if (manualControl)
            ApplyManualSettings();

        // Handle animation
        if (animateEffects)
            AnimateEffects();
    }

    private void UpdateHoverEffect()
    {
        Vector3 hoverPos = new Vector3(9999, 9999, 9999);
        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);

        if (Physics.Raycast(ray, out RaycastHit hit, 100f, hoverLayer))
        {
            hoverPos = hit.point;
            if (debugMode)
                Debug.Log($"Hover hit: {hit.collider.name} at {hit.point}");
        }

        currentHoverPos = hoverPos;
        Shader.SetGlobalVector(HoverPosID, currentHoverPos);
        Shader.SetGlobalFloat(HoverStrengthID, hoverStrength);
        Shader.SetGlobalFloat(HoverRadiusID, hoverRadius);
    }

    private void ApplyPreset(EffectPreset preset)
    {
        if (targetMaterial == null) return;

        // Reset all effects
        SetMaterialKeyword("_ENABLEFABRICSTRETCH_ON", false);
        SetMaterialKeyword("_ENABLENOISEVARIATION_ON", false);
        SetMaterialKeyword("_ENABLERIMLIGHTING_ON", false);
        SetMaterialKeyword("_ENABLEWINDCOLORSHIFT_ON", false);
        SetMaterialKeyword("_ENABLEHOVERGLOW_ON", false);

        switch (preset)
        {
            case EffectPreset.FabricStretchOnly:
                SetMaterialKeyword("_ENABLEFABRICSTRETCH_ON", true);
                break;
                
            case EffectPreset.NoiseVariationOnly:
                SetMaterialKeyword("_ENABLENOISEVARIATION_ON", true);
                break;
                
            case EffectPreset.RimLightingOnly:
                SetMaterialKeyword("_ENABLERIMLIGHTING_ON", true);
                break;
                
            case EffectPreset.WindColorShiftOnly:
                SetMaterialKeyword("_ENABLEWINDCOLORSHIFT_ON", true);
                break;
                
            case EffectPreset.HoverGlowOnly:
                SetMaterialKeyword("_ENABLEHOVERGLOW_ON", true);
                break;
                
            case EffectPreset.ClassicFlag:
                SetMaterialKeyword("_ENABLEFABRICSTRETCH_ON", true);
                SetMaterialKeyword("_ENABLERIMLIGHTING_ON", true);
                break;
                
            case EffectPreset.MagicalBanner:
                SetMaterialKeyword("_ENABLERIMLIGHTING_ON", true);
                SetMaterialKeyword("_ENABLEWINDCOLORSHIFT_ON", true);
                SetMaterialKeyword("_ENABLEHOVERGLOW_ON", true);
                break;
                
            case EffectPreset.ShowcaseAll:
                SetMaterialKeyword("_ENABLEFABRICSTRETCH_ON", true);
                SetMaterialKeyword("_ENABLENOISEVARIATION_ON", true);
                SetMaterialKeyword("_ENABLERIMLIGHTING_ON", true);
                SetMaterialKeyword("_ENABLEWINDCOLORSHIFT_ON", true);
                SetMaterialKeyword("_ENABLEHOVERGLOW_ON", true);
                break;
        }
    }

    private void ApplyManualSettings()
    {
        if (targetMaterial == null) return;

        SetMaterialKeyword("_ENABLEFABRICSTRETCH_ON", enableFabricStretch);
        SetMaterialKeyword("_ENABLENOISEVARIATION_ON", enableNoiseVariation);
        SetMaterialKeyword("_ENABLERIMLIGHTING_ON", enableRimLighting);
        SetMaterialKeyword("_ENABLEWINDCOLORSHIFT_ON", enableWindColorShift);
        SetMaterialKeyword("_ENABLEHOVERGLOW_ON", enableHoverGlow);
    }

    private void AnimateEffects()
    {
        if (targetMaterial == null) return;

        float time = Time.time * animationSpeed;
        
        // Animate wind strength
        float windStrength = 0.1f + Mathf.Sin(time) * 0.05f;
        targetMaterial.SetFloat("_WindStrength", windStrength);
        
        // Animate rim lighting
        float rimIntensity = 1f + Mathf.Sin(time * 1.5f) * 0.5f;
        targetMaterial.SetFloat("_RimIntensity", rimIntensity);
        
        // Animate noise
        float noiseIntensity = 0.2f + Mathf.Sin(time * 0.8f) * 0.1f;
        targetMaterial.SetFloat("_NoiseIntensity", noiseIntensity);
    }

    private void SetMaterialKeyword(string keyword, bool enable)
    {
        if (targetMaterial == null) return;

        if (enable)
            targetMaterial.EnableKeyword(keyword);
        else
            targetMaterial.DisableKeyword(keyword);
    }

    private void OnDrawGizmos()
    {
        if (!showGizmos || !Application.isPlaying) return;

        // Draw hover radius
        if (currentHoverPos.x < 9000)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(currentHoverPos, hoverRadius);
            
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireCube(currentHoverPos, Vector3.one * 0.1f);
        }
    }

    private void OnGUI()
    {
        if (!debugMode) return;

        GUILayout.BeginArea(new Rect(10, 10, 400, 200));
        GUILayout.Box("Ultimate Wind Shader Debug");
        
        GUILayout.Label($"Current Preset: {currentPreset}");
        GUILayout.Label($"Manual Control: {manualControl}");
        GUILayout.Label($"Hover Position: {currentHoverPos}");
        
        GUILayout.Space(10);
        GUILayout.Label("Active Effects:");
        if (targetMaterial != null)
        {
            GUILayout.Label($"• Fabric Stretch: {targetMaterial.IsKeywordEnabled("_ENABLEFABRICSTRETCH_ON")}");
            GUILayout.Label($"• Noise Variation: {targetMaterial.IsKeywordEnabled("_ENABLENOISEVARIATION_ON")}");
            GUILayout.Label($"• Rim Lighting: {targetMaterial.IsKeywordEnabled("_ENABLERIMLIGHTING_ON")}");
            GUILayout.Label($"• Wind Color Shift: {targetMaterial.IsKeywordEnabled("_ENABLEWINDCOLORSHIFT_ON")}");
            GUILayout.Label($"• Hover Glow: {targetMaterial.IsKeywordEnabled("_ENABLEHOVERGLOW_ON")}");
        }
        
        GUILayout.EndArea();
    }

    // Public methods for runtime control
    public void SetPreset(EffectPreset preset)
    {
        currentPreset = preset;
        usePresets = true;
        manualControl = false;
        ApplyPreset(preset);
    }

    public void EnableEffect(int effectNumber, bool enable)
    {
        manualControl = true;
        usePresets = false;
        
        switch (effectNumber)
        {
            case 1: enableFabricStretch = enable; break;
            case 2: enableNoiseVariation = enable; break;
            case 3: enableRimLighting = enable; break;
            case 4: enableWindColorShift = enable; break;
            case 5: enableHoverGlow = enable; break;
        }
        
        ApplyManualSettings();
    }
}