// ------------------------------------------------------------
// Contas de zoom compartilhadas entre o jogo (BossScopeHandler)
// e o HUD (medidor na tela), para os dois mostrarem a mesma coisa.
//
// Tudo e medido como AUMENTO no centro da tela ("x"), relativo a
// visao normal do jogador. Numa projecao em perspectiva o aumento
// de um FOV F em relacao ao FOV base B e tan(B/2)/tan(F/2), nao B/F.
// (As funcoes trigonometricas do ZScript usam graus.)
// ------------------------------------------------------------

class BCSMath abstract{
	//menor FOV que o GZDoom/UZDoom renderiza
	const MINFOV=5.;

	//aumento de uma visao com FOV "fov" em relacao ao FOV base
	clearscope static double MagFromFOV(double basefov,double fov){
		return tan(basefov*0.5)/tan(max(fov,0.01)*0.5);
	}

	//FOV que da o aumento "mag" em relacao ao FOV base
	clearscope static double FOVFromMag(double basefov,double mag){
		return 2.*atan(tan(basefov*0.5)/max(mag,0.0001));
	}

	//maior aumento possivel fora do scope (limite de 5 graus do motor)
	clearscope static double MaxOutsideMag(double basefov){
		return MagFromFOV(basefov,MINFOV);
	}

	//aumento que voce VE dentro do scope centralizado.
	//
	//O scope e a imagem de uma camera (FOV "scopefov") desenhada num
	//circulo de 90*tamanho unidades, num canvas de HUD de 320*(B/90)
	//de largura. Supondo que os 320 do canvas equivalem a largura de
	//referencia (4:3) do FOV do jogo:
	//  distancia focal no scope  = (D/2)/tan(scopefov/2)
	//  distancia focal na visao  = (W/2)/tan(B/2)
	//  aumento = (D/W) * tan(B/2)/tan(scopefov/2)
	//"cal" corrige essa suposicao (proporcao de tela, escala do HUD).
	clearscope static double ScopeMag(
		double basefov,double scopefov,double size,double cal
	){
		double dw=(90.*size)/(320.*basefov/90.);
		return cal*dw*MagFromFOV(basefov,scopefov);
	}

	//aumento desejado fora do scope.
	//  t     = 0..1 (fracao do zoom do scope; o mod usa 0.8)
	//  scale = 0 relativa, 1 igual ao scope
	//  scopemag    = aumento visto no scope agora
	//  narrowmag   = aumento visto no zoom maximo do scope
	clearscope static double OutsideMag(
		double basefov,double scopemag,double narrowmag,double t,int scale
	){
		if(t<=0.||scopemag<=1.)return 1.;
		double maxmag=MaxOutsideMag(basefov);
		double c=1.;
		if(scale==0&&narrowmag>maxmag){
			//relativa: encaixa a faixa toda do scope (em escala log)
			//dentro do limite do motor, para acompanhar sempre
			c=log(maxmag)/log(narrowmag);
		}
		double mag=scopemag**(t*c);
		return clamp(mag,1.,maxmag);
	}
}
