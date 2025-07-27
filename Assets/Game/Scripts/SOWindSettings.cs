using UnityEngine;

[CreateAssetMenu(menuName = "Scriptable Objects /Wind Settings", fileName = "Wind Settings")]
public class SOWindSettings : ScriptableObject
{
    public Vector3 windDirection = new Vector3(1f, 0f, 0f);
    public float windSpeed = 1f;
    public float windStrength = 0.1f;
}
