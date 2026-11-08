// Borrao gaussiano para fora do scope (Boss Scope Centralizado).
// Roda so na cena 3D; o HUD (e o scope) e desenhado depois, nitido.
void main(){
	vec2 px=u_strength/vec2(textureSize(InputTexture,0));
	vec3 sum=vec3(0.0);
	float wsum=0.0;
	for(int x=-4;x<=4;x++){
		for(int y=-4;y<=4;y++){
			float w=exp(-float(x*x+y*y)/10.0);
			sum+=texture(InputTexture,TexCoord+vec2(float(x),float(y))*px).rgb*w;
			wsum+=w;
		}
	}
	FragColor=vec4(sum/wsum,1.0);
}
