#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;

uniform float ourMix;

uniform sampler2D Tex1;
uniform sampler2D Tex2;

void main()
{
    FragColor = mix(texture(Tex1, TexCoord), texture(Tex2, TexCoord), ourMix);
}