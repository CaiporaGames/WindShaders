using UnityEngine;

public class MouseHoverWindSender : MonoBehaviour
{
    [Header("Hover Settings")]
    [SerializeField] private LayerMask hoverLayer = -1;
    [SerializeField] private float hoverRadius = 2f;
    [SerializeField] private float hoverStrength = 2f;
    
    [Header("Debug")]
    [SerializeField] private bool debugMode = false;
    [SerializeField] private bool showDebugGizmos = true;

    private Camera mainCamera;
    private static readonly int HoverPosID = Shader.PropertyToID("_HoverPosition");
    private static readonly int HoverStrengthID = Shader.PropertyToID("_HoverStrength");
    private static readonly int HoverRadiusID = Shader.PropertyToID("_HoverRadius");
    
    private Vector3 currentHoverPos;

    private void Start()
    {
        // Find camera
        mainCamera = Camera.main;
        if (mainCamera == null)
            mainCamera = FindFirstObjectByType<Camera>();

        if (mainCamera == null)
        {
            Debug.LogError("MouseHoverWindSender: No camera found! Make sure you have a camera tagged as 'MainCamera'");
            enabled = false;
            return;
        }

        // Initialize shader properties
        Shader.SetGlobalFloat(HoverStrengthID, hoverStrength);
        Shader.SetGlobalFloat(HoverRadiusID, hoverRadius);
        currentHoverPos = new Vector3(9999, 9999, 9999);
        Shader.SetGlobalVector(HoverPosID, currentHoverPos);
    }

    private void Update()
    {
        if (mainCamera == null) return;

        Vector3 hoverPos = new Vector3(9999, 9999, 9999); // Default offscreen position
        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);

        // Cast ray to find hover position
        if (Physics.Raycast(ray, out RaycastHit hit, 100f, hoverLayer))
        {
            hoverPos = hit.point;
        }

        // Update shader properties
        currentHoverPos = hoverPos;
        Shader.SetGlobalVector(HoverPosID, currentHoverPos);
        Shader.SetGlobalFloat(HoverStrengthID, hoverStrength);
        Shader.SetGlobalFloat(HoverRadiusID, hoverRadius);
    }

    private void OnDrawGizmos()
    {
        if (!showDebugGizmos || !Application.isPlaying) return;

        // Draw hover radius
        if (currentHoverPos.x < 9000) // If not at default offscreen position
        {
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(currentHoverPos, hoverRadius);
            
            // Draw a small marker at the exact hover point
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireCube(currentHoverPos, Vector3.one * 0.1f);
        }
    }

}