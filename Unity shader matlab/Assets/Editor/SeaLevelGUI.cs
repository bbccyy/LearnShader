using UnityEngine;
using UnityEditor;

public class SeaLevelGUI : BaseGUI
{

    bool useMeshWave = false;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor;
        this.properties = properties;

        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TextureProperty(mainTex, "MainTex");

        MaterialProperty normalTex = FindProperty("_NormalTex");
        editor.TextureProperty(normalTex, "NormalTex");

        MaterialProperty noiseTex = FindProperty("_NoiseTex");
        editor.TextureProperty(noiseTex, "NoiseTex");

        MaterialProperty flowTex = FindProperty("_FlowTex");
        editor.TextureProperty(flowTex, "FlowTex");

        EditorGUI.indentLevel += 1;
        MaterialProperty farCol = FindProperty("_FarColor");
        editor.ColorProperty(farCol, "Far Color");

        MaterialProperty nearCol = FindProperty("_NearColor");
        editor.ColorProperty(nearCol, "Near Color");

        MaterialProperty specCol = FindProperty("_SpecColor");
        editor.ColorProperty(specCol, "Specular Color");

        MaterialProperty uJump = FindProperty("_UJump");
        editor.RangeProperty(uJump, "UJump");
        MaterialProperty vJump = FindProperty("_VJump");
        editor.RangeProperty(vJump, "VJump");

        MaterialProperty tiling = FindProperty("_Tiling");
        editor.ShaderProperty(tiling, "Tiling");
        MaterialProperty speed = FindProperty("_Speed");
        editor.ShaderProperty(speed, "Speed");
        MaterialProperty flowStrength = FindProperty("_FlowStrength");
        editor.ShaderProperty(flowStrength, "Flow Strength");
        MaterialProperty flowOffset = FindProperty("_FlowOffset");
        editor.ShaderProperty(flowOffset, "Flow Offset");

        // use mesh wave
        useMeshWave = isKeywordEnabled("_MESH_WAVE");
        useMeshWave = EditorGUILayout.Toggle("UseMeshWave", useMeshWave, new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(20f)});
        SetKeyWord("_MESH_WAVE", useMeshWave);
        if (useMeshWave)
        {
            MaterialProperty waveA = FindProperty("_WaveA");
            editor.VectorProperty(waveA, "Wave Dir(2D), z:steepness, w:wavelength");
            MaterialProperty waveB = FindProperty("_WaveB");
            editor.VectorProperty(waveB, "Wave DirB");
            MaterialProperty waveC = FindProperty("_WaveC");
            editor.VectorProperty(waveC, "Wave DirC");
        }

        MaterialProperty glossiness = FindProperty("_Glossiness");
        editor.RangeProperty(glossiness, "Glossiness");
        MaterialProperty specularStrength = FindProperty("_SpecularStrength");
        editor.RangeProperty(specularStrength, "Specular Strength");

        MaterialProperty cameraPos = FindProperty("_CameraPos");
        editor.VectorProperty(cameraPos, "Camera Position");

        MaterialProperty lightDir = FindProperty("_LightDir");
        editor.VectorProperty(lightDir, "Light Dir");
        EditorGUI.indentLevel -= 1;
    }
}
