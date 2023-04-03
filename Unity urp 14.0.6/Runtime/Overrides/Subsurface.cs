using System;

namespace UnityEngine.Rendering.Universal
{
    /// <summary>
    /// A volume component that holds settings for the Subsurface effect.
    /// </summary>
    [Serializable, VolumeComponentMenuForRenderPipeline("Post-processing/Subsurface", typeof(UniversalRenderPipeline))]
    public sealed partial class Subsurface : VolumeComponent, IPostProcessComponent
    {
        /// <summary>
        /// Set the level of brightness to filter out pixels under this level.
        /// This value is expressed in gamma-space.
        /// A value above 0 will disregard energy conservation rules.
        /// </summary>
        [Header("Subsurface")]
        /// <summary>
        /// Controls the strength of the bloom filter.
        /// </summary>
        [Tooltip("TODO")]
        public MinFloatParameter intensity = new MinFloatParameter(0f, 0f);


        /// <inheritdoc/>
        public bool IsActive() => intensity.value > 0f;

        /// <inheritdoc/>
        public bool IsTileCompatible() => false;
    }

}
