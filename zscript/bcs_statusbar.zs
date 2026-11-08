// Barra de status: centraliza o scope das armas com scope do HD
// (perfis em bcs_scopes.zs).
// Herda de HDRNStatusBar para conviver com o HUD em uso.
class BossScopeStatusBar:HDRNStatusBar{
	transient cvar bcs_enabled;
	transient cvar bcs_modon;
	transient cvar bcs_size;
	transient cvar bcs_outside;
	transient cvar bcs_blur;

	//pedido de borrao neste quadro (ligado em DrawHDXHair)
	transient bool bcs_wantblur;
	transient bool bcs_blurison;

	override void Draw(int state,double TicFrac){
		bcs_wantblur=false;
		super.Draw(state,TicFrac);

		//o shader so afeta o mundo 3D; o scope (desenhado no HUD) fica nitido
		bool want=bcs_wantblur;
		if(want){
			double str=bcs_blur?clamp(bcs_blur.getfloat(),0.5,10.):3.;
			PPShader.SetUniform1f("BCSBlur","u_strength",str);
		}
		if(want!=bcs_blurison){
			PPShader.SetEnabled("BCSBlur",want);
			bcs_blurison=want;
		}
	}

	override void DrawHDXHair(hdplayerpawn hpl,double ticfrac){
		if(!bcs_enabled){
			bcs_enabled=cvar.getcvar("bcs_enabled",cplayer);
			bcs_modon=cvar.getcvar("bcs_modon",cplayer);
			bcs_size=cvar.getcvar("bcs_size",cplayer);
			bcs_outside=cvar.getcvar("bcs_outside",cplayer);
			bcs_blur=cvar.getcvar("bcs_blur",cplayer);
		}

		let wp=hdweapon(cplayer.readyweapon);
		int scopeid=BCSScopes.Identify(wp);

		//arma sem perfil de scope (ou addon desligado): comportamento original do HD
		if(
			!wp
			||scopeid==BCSScopes.SC_NONE
			||!bcs_enabled
			||!bcs_enabled.getbool()
			||(bcs_modon&&!bcs_modon.getbool())
			||!hd_noscope
		){
			super.DrawHDXHair(hpl,ticfrac);
			return;
		}

		// --- copia da logica original de DrawHDXHair (crosshair.zs) ---
		int nscp=hd_noscope.getint();
		if(
			nscp>=4
			||(
				!(cplayer.cmd.buttons&(BT_USE|BT_ZOOM))
				&&(
					nscp>1
					||hd_hudusedelay.getint()<-1
				)
			)
		)return;

		bool sightbob=hd_sightbob.getbool();
		vector2 bob=hpl.crossbob;
		vector2 lastbob=hpl.lastcrossbob;
		//FOV "normal" do jogador, sem o zoom de fora do scope que o
		//BossScopeHandler pode aplicar; assim o scope nao muda de tamanho
		//e a mira nao some quando o FOV real fica abaixo de 13
		double fov=cplayer.desiredfov*(hpl.recoilfov>0?hpl.recoilfov:1.);

		if(
			hpl.barehanded
			||hpl.nocrosshair>0
			||(
				!sightbob
				&&hpl.countinv("IsMoving")
			)
			||abs(bob.x)>75
			||abs(bob.y)>80
			||fov<13
		)return;

		bob=lastbob+((bob-lastbob)*ticfrac);

		actor hpc=hpl.scopecamera;
		int buttons=cplayer.cmd.buttons;

		bool scopeview=
			!!hpc
			&&(
				!nscp
				||(
					buttons&BT_ZOOM
					&&nscp<3
					&&nscp>0
				)
			)
		;
		// --- fim da copia ---

		//so mira de ferro (ou arma num modo sem scope, como o lanca-granadas):
		//exatamente como o HD desenha, incluindo a escala de mira do HD
		if(!scopeview||!BCSScopes.HasScopeNow(wp,scopeid)){
			double scl=fov/(90.*clamp(hd_crosshairscale.getfloat(),0.1,3.0));
			SetSize(0,int(320.*scl),int(200.*scl));
			BeginHUD(forcescaled:true);
			wp.DrawSightPicture(self,wp,hpl,sightbob,bob,fov,scopeview,hpc);
			return;
		}

		//scope: ignora o hd_crosshairscale do HD; o tamanho vem so do
		//"Tamanho do scope" deste mod (bcs_size)
		double scl=fov/90.;
		SetSize(0,int(320.*scl),int(200.*scl));
		BeginHUD(forcescaled:true);

		//scope: centralizado, no lugar da mira de ferro
		//fora do scope: so enquanto Zoom esta pressionado
		//(no modo passivo 0 o scope fica sempre na tela)
		int outside=0;
		if(buttons&BT_ZOOM&&bcs_outside)outside=bcs_outside.getint();
		if(outside==2)bcs_wantblur=true;

		DrawCenteredScope(scopeid,wp,hpl,bob,fov,hpc,outside==1);
	}

	// ------------------------------------------------------------
	// Desenho centralizado. Cada scope e redesenhado com as medidas
	// originais do HD multiplicadas por "f", que deixa a imagem da
	// camera com 90*tamanho unidades de largura (o tamanho do Boss em
	// 1.0). Assim todos os scopes ficam do mesmo tamanho na tela.
	// ------------------------------------------------------------
	transient int bcs_cx,bcs_cy,bcs_cw,bcs_ch;

	//escuro fora de um retangulo centrado (meia-largura hw, meia-altura hh)
	void BlackoutAround(vector2 c,double hw,double hh){
		color blk=color(255,0,0,0);
		double big=10000.;
		double x0=c.x-hw+1.;
		double y0=c.y-hh+1.;
		double x1=c.x+hw-1.;
		double y1=c.y+hh-1.;
		Fill(blk,-big,-big,x0+big,2.*big,DI_SCREEN_CENTER);
		Fill(blk,x1,-big,big,2.*big,DI_SCREEN_CENTER);
		Fill(blk,x0,-big,x1-x0,y0+big,DI_SCREEN_CENTER);
		Fill(blk,x0,y1,x1-x0,big,DI_SCREEN_CENTER);
	}

	//inicio comum dos scopes redondos: preto em volta (opcional),
	//recorte, fundo preto e imagem da camera.
	//  camscale = escala original da camera no HD (DrawCircle)
	//  clip     = lado original do recorte quadrado no HD
	//  parallax = quanto a camera se move com o balanco no HD (bob*N)
	//devolve f (fator de escala) e o centro da camera
	double, vector2 BeginRoundScope(
		name camtex,double degree,actor hpc,vector2 bob,
		double camscale,double clip,double parallax,bool blackout
	){
		double k=clamp(bcs_size.getfloat(),0.5,6.0);
		let cam=texman.CheckForTexture(camtex,TexMan.Type_Any);
		int camw,camh;
		[camw,camh]=texman.GetSize(cam);
		double f=(90.*k)/max(1.,camw*camscale);

		double half=clip*f*0.5;
		if(blackout)BlackoutAround(bob,half,half);

		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		bcs_cx=cx;bcs_cy=cy;bcs_cw=cw;bcs_ch=ch;
		SetClipRect(bob.x-half,bob.y-half,half*2.,half*2.,DI_SCREEN_CENTER);
		Fill(color(255,0,0,0),bob.x-half,bob.y-half,half*2.,half*2.,DI_SCREEN_CENTER);

		texman.setcameratotexture(hpc,camtex,degree);
		//camera se move (parallax-1)x mais que a moldura, como no HD
		vector2 camoffs=bob+bob*((parallax-1.)*f);
		DrawCircle(cam,camoffs,camscale*f,usePixelRatio:true);
		return f,camoffs;
	}
	void EndClip(){
		screen.SetClipRect(bcs_cx,bcs_cy,bcs_cw,bcs_ch);
	}

	//moldura/retículo desenhados como imagem, centrados no scope
	void ScopeImage(string img,vector2 bob,double scl,double f){
		DrawImage(img,bob,DI_SCREEN_CENTER|DI_ITEM_CENTER,scale:(scl*f,scl*f));
	}
	//texto preto do scope, numa posicao relativa ao centro (unidades do HD)
	void ScopeText(string txt,vector2 bob,double x,double y,double f){
		DrawString(
			mAmountFont,txt,(x*f+bob.x,y*f+bob.y),
			DI_SCREEN_CENTER|DI_TEXT_ALIGN_RIGHT,Font.CR_BLACK
		);
	}
	//numero pequeno do HD (drawnum), mas com o tamanho escalado
	void ScopeNum(int num,vector2 bob,double x,double y,double f,int fnt,double alpha){
		DrawString(
			pnewsmallfont,FormatNumber(num),(x*f+bob.x,y*f+bob.y),
			DI_SCREEN_CENTER|DI_TEXT_ALIGN_RIGHT,fnt,alpha,scale:(0.5*f,0.5*f)
		);
	}

	void DrawCenteredScope(
		int id,hdweapon hdw,hdplayerpawn hpl,vector2 bob,double fov,actor hpc,bool blackout
	){
		double degree,narrowest;
		[degree,narrowest]=BCSScopes.ScopeFOV(hdw,id);
		double deg=1./degree;
		double f;
		vector2 camoffs;

		switch(id){
		case BCSScopes.SC_BOSS:{
			[f,camoffs]=BeginRoundScope("HDXCAM_BOSS",degree,hpc,bob,0.125,89.,3.,blackout);
			//mesmo contorno de bug do GZDoom usado no HD original
			if((bob.y/fov)<0.4){
				let cam=texman.CheckForTexture("HDXCAM_BOSS",TexMan.Type_Any);
				let reticle=texman.CheckForTexture("bossret1",TexMan.Type_Any);
				double camsize=texman.GetSize(cam);
				double rs=camsize/texman.GetSize(reticle);
				if(hdw.weaponstatus[0]&BOSSF_FRONTRETICLE){
					DrawCircle(reticle,camoffs,.5*rs*f,bob*deg*5-bob,1.6*deg*f);
				}else{
					DrawCircle(reticle,bob,.5*rs*f,uvScale:.5*f);
				}
			}
			EndClip();
			ScopeImage("bossscope",bob,1.24,f);
			ScopeText(string.format("%.1f",degree),bob,6,45,f);
			ScopeText(string.format("%i",hdw.weaponstatus[BOSSS_DROPADJUST]),bob,6,-51,f);
			break;
		}
		case BCSScopes.SC_ZM66:
		case BCSScopes.SC_VULC:{
			[f,camoffs]=BeginRoundScope("HDXCAM_ZM66",degree,hpc,bob,0.075,57.,3.,blackout);
			EndClip();
			ScopeImage("zm66scop",bob,0.82,f);
			ScopeText(string.format("%.1f",degree),bob,6,27,f);
			break;
		}
		case BCSScopes.SC_LIB:{
			[f,camoffs]=BeginRoundScope("HDXCAM_LIB",degree,hpc,bob,0.08825,72.,2.,blackout);
			if((bob.y/fov)<0.4){
				let cam=texman.CheckForTexture("HDXCAM_LIB",TexMan.Type_Any);
				let reticle=texman.CheckForTexture(
					(hdw.weaponstatus[0]&LIBF_ALTRETICLE)?"reticle2":"reticle1",
					TexMan.Type_Any
				);
				double camsize=texman.GetSize(cam);
				double rs=camsize/texman.GetSize(reticle);
				if(hdw.weaponstatus[0]&LIBF_FRONTRETICLE){
					DrawCircle(reticle,camoffs,393*rs*f,bob*4,1.6*deg*f);
				}else{
					DrawCircle(reticle,bob,.403*rs*f,uvScale:.52*f);
				}
			}
			EndClip();
			ScopeImage("libscope",bob,1.,f);
			ScopeText(string.format("%.1f",degree),bob,6,35,f);
			ScopeText(string.format("%i",hdw.weaponstatus[LIBS_DROPADJUST]),bob,6,-43,f);
			break;
		}
		case BCSScopes.SC_BRON:{
			[f,camoffs]=BeginRoundScope("HDXCAM_BRON",degree,hpc,bob,0.085,50.,5.,blackout);
			EndClip();
			ScopeImage("brret",bob,1.,f);
			ScopeImage("brontoscope",bob,1.,f);
			break;
		}
		case BCSScopes.SC_RL:{
			[f,camoffs]=BeginRoundScope("HDXCAM_RLAUN",degree,hpc,bob,0.085,56.,5.,blackout);
			EndClip();
			ScopeImage("rlret",bob,0.82,f);
			ScopeImage("rlscop",bob,0.82,f);
			let rl=HDRL(hdw);
			if(rl){
				if(
					(level.time&(1|2))
					||rl.rangefinder>14
				)ScopeNum(rl.rangefinder,bob,4,-23,f,Font.CR_RED,0.5);
				if(hdw.weaponstatus[RLS_CHAMBER]<=1){
					int airburst=hdw.airburst;
					if(airburst)ScopeNum(max(10,airburst/100),bob,4,12,f,Font.CR_WHITE,0.5);
				}
			}
			break;
		}
		case BCSScopes.SC_TB:{
			//scope retangular: a camera e uma imagem, sem recorte
			double k=clamp(bcs_size.getfloat(),0.5,6.0);
			name ctex="HDXCAM_TB";
			let cam=texman.CheckForTexture(ctex,TexMan.Type_Any);
			int camw,camh;
			[camw,camh]=texman.GetSize(cam);
			double sx=0.25/1.2;
			double sy=0.25;
			f=(90.*k)/max(1.,camw*sx);
			if(blackout)BlackoutAround(bob,camw*sx*f*0.5,camh*sy*f*0.5);

			bool alt=hdw.weaponstatus[0]&TBF_ALT;
			texman.setcameratotexture(hpc,ctex,3);
			DrawImage(
				ctex,bob,DI_SCREEN_CENTER|DI_ITEM_CENTER,
				alpha:alt?(hpl.flip?0.7:0.8):1.,scale:(sx*f,sy*f)
			);
			let tb=ThunderBuster(hdw);
			if(tb){
				ScopeNum(min(tb.rangefinder,999),bob,24,-24,f,
					(
						tb.rangefinder>=10
						&&tb.rangefinder<hdw.weaponstatus[TBS_MAXRANGEDISPLAY]
					)?Font.CR_GRAY:Font.CR_RED,
					0.4
				);
			}
			ScopeNum(hdw.weaponstatus[TBS_MAXRANGEDISPLAY],bob,24,-16,f,Font.CR_WHITE,0.4);
			if(alt){
				DrawString(
					pnewsmallfont,FormatNumber(int(2000/HDCONST_ONEMETRE)),
					(23*f+bob.x,-17*f+bob.y),DI_SCREEN_CENTER|DI_TEXT_ALIGN_RIGHT,
					Font.CR_BLACK,1.,scale:(0.5*f,0.5*f)
				);
			}
			ScopeImage("tbwindow",bob,1.,f);
			//ponto vermelho: no HD se move 3.6x o balanco
			vector2 dotb=bob+bob*(2.6*f);
			double dotoff=max(abs(bob.x*3.6),abs(bob.y*3.6));
			if(dotoff<40){
				double ds=alt?(hpl.flip?3.:1.):2.;
				DrawImage(
					"redpxl",dotb,DI_SCREEN_CENTER|DI_ITEM_TOP,
					alpha:(alt?0.4:0.9)*(1.-dotoff*0.04),scale:(ds*f,ds*f)
				);
			}
			break;
		}
		}
	}
}
