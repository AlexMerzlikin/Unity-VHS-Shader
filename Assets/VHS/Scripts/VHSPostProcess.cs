using UnityEngine;

namespace VHS.Scripts
{
    [ExecuteInEditMode]
    public class VhsPostProcess : MonoBehaviour
    {
        private static readonly int TimeParam = Shader.PropertyToID("_TimeParam");
        public Material _vhsMaterial;

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (_vhsMaterial != null)
            {
                _vhsMaterial.SetFloat(TimeParam, Time.time);
                Graphics.Blit(src, dest, _vhsMaterial);
            }
            else
            {
                Graphics.Blit(src, dest);
            }
        }
    }
}