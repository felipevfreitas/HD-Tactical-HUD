// ------------------------------------------------------------
// Quais armas tem scope e qual o zoom de cada uma.
// Usado pelo HUD (desenho) e pelo jogo (zoom de fora e sensibilidade).
//
// Cada arma do HD desenha o scope com codigo proprio, entao aqui ha um
// perfil por arma. Armas de outros mods que DERIVAM destas (ex.: uma
// variante do ZM66) usam o perfil da arma-mae automaticamente. Armas
// com scope totalmente proprio continuam com o desenho original.
// ------------------------------------------------------------

class BCSScopes abstract{
	enum EScope{
		SC_NONE=0,
		SC_BOSS,
		SC_ZM66,
		SC_VULC,
		SC_LIB,
		SC_BRON,
		SC_RL,
		SC_TB,
	}

	clearscope static int Identify(hdweapon wp){
		if(!wp)return SC_NONE;
		//ordem importa so se uma classe derivar de outra da lista
		if(wp is "BossRifle")return SC_BOSS;
		if(wp is "ZM66AssaultRifle")return SC_ZM66;
		if(wp is "Vulcanette")return SC_VULC;
		if(wp is "LiberatorRifle")return SC_LIB;
		if(wp is "Brontornis")return SC_BRON;
		if(wp is "HDRL")return SC_RL;
		if(wp is "ThunderBuster")return SC_TB;
		return SC_NONE;
	}

	//a arma esta num modo com scope? (modo granada nao tem scope)
	clearscope static bool HasScopeNow(hdweapon wp,int id){
		switch(id){
		case SC_ZM66:return !(wp.weaponstatus[0]&ZM66F_GLMODE);
		case SC_LIB:return !(wp.weaponstatus[0]&LIBF_GRENADEMODE);
		case SC_RL:return !(wp.weaponstatus[0]&RLF_GRENADEMODE);
		case SC_NONE:return false;
		default:return true;
		}
	}

	//FOV atual do scope e o menor FOV (zoom maximo) que ele alcanca,
	//com os mesmos limites do A_ZoomAdjust de cada arma
	clearscope static double, double ScopeFOV(hdweapon wp,int id){
		switch(id){
		case SC_BOSS:
			return
				max(0.1,0.1*wp.weaponstatus[BOSSS_ZOOM]),
				(wp.weaponstatus[0]&BOSSF_FRONTRETICLE)?1.2:0.5;
		case SC_ZM66:
			return max(0.1,0.1*wp.weaponstatus[ZM66S_ZOOM]),1.6;
		case SC_VULC:
			return max(0.1,0.1*wp.weaponstatus[VULCS_ZOOM]),1.6;
		case SC_LIB:
			return
				max(0.1,0.1*wp.weaponstatus[LIBS_ZOOM]),
				(wp.weaponstatus[0]&LIBF_FRONTRETICLE)?2.0:0.6;
		case SC_BRON:return 6.,6.;
		case SC_RL:return 4.,4.;
		case SC_TB:return 3.,3.;
		}
		return 90.,90.;
	}

	//largura da imagem da camera no desenho ORIGINAL do HD
	//(unidades do HUD; o Boss e 90). Usado na sensibilidade quando o
	//scope centralizado esta desligado.
	clearscope static double OriginalCamWidth(int id){
		switch(id){
		case SC_BOSS:return 720*0.125;
		case SC_ZM66:
		case SC_VULC:return 720*0.075;
		case SC_LIB:return 720*0.08825;
		case SC_BRON:
		case SC_RL:return 720*0.085;
		case SC_TB:return 308*0.25/1.2;
		}
		return 90.;
	}
}
