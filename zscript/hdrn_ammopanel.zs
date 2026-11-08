// ------------------------------------------------------------
// Tactical HUD - ammo panel (bottom right), tactical-shooter style
//
//   [weapon list]                      (on weapon switch)
//   [ LABEL        ] [fire]
//   [ + m m M   N  ] [mode]
//
// - M = mag in the gun (rightmost), with a bar above it: lit = round
//   chambered. Up to 3 mags total; "+" when there are more. N = total mags.
// - Empty mag: dotted outline blinking red. Dirty ZM66 mag: red stripes.
// - Shotguns: "reserve | side saddles + in the gun", with a split bar
//   above the last number (long part = live shell in the chamber, short
//   part = anything in the chamber), number red when jammed.
// - Grenade launcher mode: loaded grenade + spares, no fire mode column.
// - Fire mode column: fixed slots top->bottom (auto / burst / semi...),
//   only the weapon's modes are drawn, missing ones stay blank.
//
// Shows instantly on inspect / reload / weapon switch (fire mode change:
// only the fire mode column), fades out after a fixed time; firing during
// the fade-out brings it back to full and restarts the fade. HD's sprint /
// jump / mantle "weapon" is ignored: the panel keeps the real weapon.
// ------------------------------------------------------------
extend class HDRNStatusBar{

	enum HDRNPanelConsts{
		RN_PFADE=10,		//fade-out tics (0.3 s)
		RN_WLFADEIN=6,		//weapon list fade-in tics (0.17 s), like Insurgency
		RN_T_LIST=105,		//weapon list after a switch (3 s)
		RN_T_SWITCH=150,	//ammo + fire mode after a switch (4.3 s)
		RN_T_INSPECT=122,
		RN_T_FMONLY=70,		//fire mode column alone after a mode change (2 s)	//ammo + fire mode on inspect / reload (3.5 s)

		RN_FM_NONE=0,
		RN_FM_SEMI=1,
		RN_FM_BURST=2,
		RN_FM_AUTO=3,
		RN_FM_PUMP=4,

		RN_AK_MAGS=0,		//panel kinds
		RN_AK_SHELLS=1,
		RN_AK_GRENADES=2,	//grenade launcher: loaded + spares as icons
		RN_AK_COUNT=3,		//just a number (hand grenades)
	}

	//visibility
	int rn_aptimer,rn_fmtimer,rn_wltimer;
	double rn_apalf,rn_fmalf,rn_wlalf;
	int rn_lastinspect;

	//panel contents (rebuilt every frame)
	int rn_akind;
	string rn_alabel;
	double rn_acur;			//mag in the gun: fill 0..1, -1 = no mag
	bool rn_acurdirty;
	int rn_achamber;		//0 empty, 1 spent, 2 live
	array<double> rn_aspare;	//spare mags shown (next to load first)
	bool rn_amore;
	int rn_atotal;
	int rn_ares,rn_asad,rn_aingun;
	bool rn_ajam,rn_apump;
	int rn_afm[3];
	int rn_afmsel;
	bool rn_ahasfm;
	transient cvar rn_apshowempty;
	bool rn_adouble;
	array<int> rn_acyl;	//revolver: per chamber 0 empty / 1 spent / 2 live
	bool rn_aempty;		//nothing left to fire
	bool rn_lastatk,rn_wasempty;
	int rn_achamber2;
	hdweapon rn_realwep;	//last real weapon (never the sprint one)


	// ------------------------------------------------------------
	// visibility
	// ------------------------------------------------------------
	void RN_PanelShow(int ammo,int fm,int list){
		if(ammo>0){rn_aptimer=max(rn_aptimer,ammo);rn_apalf=1;}
		if(fm>0){rn_fmtimer=max(rn_fmtimer,fm);rn_fmalf=1;}
		if(list>0)rn_wltimer=max(rn_wltimer,list);	//fades in (see RN_PanelTick)
	}

	//the weapon the panel is about: the one being switched to, or the one
	//in hand - but never HD's sprint/jump/mantle "weapon" (NullWeapon):
	//while running, the panel keeps showing the weapon from before
	hdweapon RN_DispWeapon(){
		if(rn_realwep&&rn_realwep.owner==cplayer.mo)return rn_realwep;
		let rw=hdweapon(cplayer.readyweapon);
		if(rw&&rw is "NullWeapon")return null;
		return rw;
	}

	void RN_PanelTick(){
		//follow the existing triggers (inspect key, hold, reload, pump...).
		//A quick look (pump) lasts as long as the old timer says, a full
		//inspect always RN_T_INSPECT; holding the key/reload keeps it full
		if(inspecttimer>0&&(inspecttimer>rn_lastinspect+1||inspecttimer>=rn_lastinspect)){
			if(rn_inspectweaponly)RN_PanelShow(inspecttimer,0,0);
			else RN_PanelShow(RN_T_INSPECT,RN_T_INSPECT,0);
		}
		rn_lastinspect=inspecttimer;

		//fire mode changed: only the fire mode column
		//(the status bar sets it to 35 and already counted it down once this tic)
		if(rn_modeflash==34){
			//with the whole panel up, it just follows the panel's timing;
			//on its own it stays RN_T_FMONLY
			if(rn_aptimer>0){rn_fmtimer=rn_aptimer;rn_fmalf=1;}
			else RN_PanelShow(0,RN_T_FMONLY,0);
		}

		//weapon switch: everything. Only a change of the real weapon counts,
		//so going into a sprint/jump/mantle and back out is ignored
		let pw=cplayer.pendingweapon;
		weapon target=pw!=WP_NOCHANGE?pw:cplayer.readyweapon;
		let ht=hdweapon(target);
		if(ht&&!(ht is "NullWeapon")&&ht!=rn_realwep){
			if(rn_realwep)RN_PanelShow(RN_T_SWITCH,RN_T_SWITCH,RN_T_LIST);
			rn_realwep=ht;
		}

		//empty weapon: trying to fire shows ammo + fire mode; the fire mode
		//column then fades as usual, but the ammo stays up for as long as
		//the weapon is empty (until it's reloaded or put away)
		bool atk=!!(cplayer.cmd.buttons&BT_ATTACK);
		bool empty=RN_BuildPanel(RN_DispWeapon())&&(rn_aempty||rn_ajam);	//(jammed behaves the same)
		//(a new click only - holding fire as it runs dry doesn't count - and only
		//if the ammo isn't already up; once it's stuck there, clicking again
		//doesn't bring the fire mode back)
		if(empty&&atk&&!rn_lastatk&&rn_apalf<=0)RN_PanelShow(RN_T_INSPECT,RN_T_INSPECT,0);
		if(empty&&rn_apalf>0){
			rn_aptimer=max(rn_aptimer,1);
			rn_apalf=1;
		}
		rn_lastatk=atk;
		rn_wasempty=empty;

		//firing during the fade-out brings it back to full and restarts the fade
		if(cplayer.cmd.buttons&BT_ATTACK){
			if(rn_apalf>0)rn_apalf=1;
			//(the fire mode column only when it's up together with the ammo;
			//shown alone after a mode change, firing doesn't bring it back)
			if(rn_fmalf>0&&rn_apalf>0)rn_fmalf=1;
		}

		//ammo/fire mode shown at once, the weapon list fades in; then a short fade-out
		if(rn_aptimer>0){rn_aptimer--;rn_apalf=1;}
		else rn_apalf=max(0.,rn_apalf-1./RN_PFADE);
		if(rn_fmtimer>0){rn_fmtimer--;rn_fmalf=1;}
		else rn_fmalf=max(0.,rn_fmalf-1./RN_PFADE);
		if(rn_wltimer>0){rn_wltimer--;rn_wlalf=min(1.,rn_wlalf+1./RN_WLFADEIN);}
		else rn_wlalf=max(0.,rn_wlalf-1./RN_PFADE);
	}


	// ------------------------------------------------------------
	// contents
	// ------------------------------------------------------------
	void RN_SetFM(int a,int b,int c,int sel){
		rn_afm[0]=a;rn_afm[1]=b;rn_afm[2]=c;
		rn_afmsel=sel;
		rn_ahasfm=true;
	}

	//weapons handled by the new panel (HD's own readout is hidden for them)
	bool RN_PanelWeapon(hdweapon w){
		return w&&(
			w is "HDPistol"
			||w is "HDSMG"
			||w is "ZM66AssaultRifle"
			||w is "LiberatorRifle"
			||w is "Hunter"
			||w is "Slayer"
			||w is "BossRifle"
			||w is "HDRevolver"
			||w is "HDGrenadeThrower"
		);
	}

	bool RN_BuildPanel(hdweapon w){
		if(!RN_PanelWeapon(w))return false;
		rn_ahasfm=false;
		rn_afm[0]=RN_FM_NONE;rn_afm[1]=RN_FM_NONE;rn_afm[2]=RN_FM_NONE;
		rn_aspare.clear();
		rn_amore=false;rn_ajam=false;rn_apump=false;rn_acurdirty=false;rn_adouble=false;rn_aempty=false;rn_acyl.clear();
		int st=w.weaponstatus[0];

		//hand grenades: just how many are left
		if(w is "HDGrenadeThrower"){
			rn_akind=RN_AK_COUNT;
			rn_alabel="$HDRN_AP_GRENADES";
			let gw=HDGrenadeThrower(w);
			rn_atotal=gw.grenadeammotype?hpl.countinv(gw.grenadeammotype):0;
			rn_aempty=rn_atotal<=0;
			return true;
		}

		//pump shotgun
		if(w is "Hunter"){
			rn_akind=RN_AK_SHELLS;
			rn_alabel="$HDRN_AP_SHELLS";
			rn_achamber=clamp(w.weaponstatus[HUNTS_CHAMBER],0,2);
			rn_aingun=max(0,w.weaponstatus[HUNTS_TUBE])+(rn_achamber==2?1:0);
			rn_asad=clamp(w.weaponstatus[SHOTS_SIDESADDLE],0,12);
			rn_ares=hpl.countinv("HDShellAmmo");
			rn_ajam=!!(st&HUNTF_JAMMED);
			rn_apump=true;
			rn_aempty=rn_aingun<=0;
			if(!(st&HUNTF_EXPORT)){
				int fm=w.weaponstatus[HUNTS_FIREMODE];	//0 pump, 1 semi, 2 auto
				int sel=fm>=2?0:fm==1?1:2;
				if(st&HUNTF_CANFULLAUTO)RN_SetFM(RN_FM_AUTO,RN_FM_SEMI,RN_FM_PUMP,sel);
				else RN_SetFM(RN_FM_NONE,RN_FM_SEMI,RN_FM_PUMP,sel);
			}
			return true;
		}

		//double barrel: one chamber per barrel, no fire modes
		if(w is "Slayer"){
			rn_akind=RN_AK_SHELLS;
			rn_alabel="$HDRN_AP_SHELLS";
			rn_adouble=true;
			rn_achamber=clamp(w.weaponstatus[SLAYS_CHAMBER1],0,2);
			rn_achamber2=clamp(w.weaponstatus[SLAYS_CHAMBER2],0,2);
			rn_aingun=(rn_achamber==2?1:0)+(rn_achamber2==2?1:0);
			rn_aempty=rn_aingun<=0;
			rn_asad=clamp(w.weaponstatus[SHOTS_SIDESADDLE],0,12);
			rn_ares=hpl.countinv("HDShellAmmo");
			return true;
		}

		//bolt-action rifle: "reserve | in the gun", split chamber bar like the
		//pump shotgun (chamber 3/4 = stuck case = jammed)
		if(w is "BossRifle"){
			rn_akind=RN_AK_SHELLS;
			rn_alabel="$HDRN_AP_ROUNDS";
			int ch=w.weaponstatus[BOSSS_CHAMBER];
			rn_ajam=ch>2;
			rn_achamber=ch>2?ch-2:clamp(ch,0,2);
			rn_aingun=clamp(w.weaponstatus[BOSSS_MAG]%100,0,10)+(ch==2?1:0);
			rn_asad=-1;
			int res=hpl.countinv("SevenMilAmmo")+hpl.countinv("SevenMilAmmoRecast");
			let clips=hdmagammo(hpl.findinventory("HD7mClip"));
			if(clips)for(int i=0;i<clips.mags.size();i++)res+=max(0,clips.mags[i]%100);
			rn_ares=res;
			rn_aempty=rn_aingun<=0;
			return true;
		}

		//revolver: "reserve | in the cylinder", one bar segment per chamber
		if(w is "HDRevolver"){
			rn_akind=RN_AK_SHELLS;
			rn_alabel="$HDRN_AP_ROUNDS";
			rn_aingun=0;
			for(int i=BUGS_CYL1;i<=BUGS_CYL6;i++){
				int c=w.weaponstatus[i];	//1/3 spent, 2/4 live (9mm / .355)
				int cs=c<=0?0:(c==2||c==4)?2:1;
				rn_acyl.push(cs);
				if(cs==2)rn_aingun++;
			}
			rn_asad=-1;
			rn_ares=hpl.countinv("HDRevolverAmmo");
			rn_aempty=rn_aingun<=0;
			return true;
		}

		//grenade launcher mode (ZM66 / Liberator): loaded grenade + spares
		bool glmode=
			(w is "ZM66AssaultRifle"&&(st&ZM66F_GLMODE))
			||(w is "LiberatorRifle"&&(st&LIBF_GRENADEMODE))
		;
		if(glmode){
			rn_akind=RN_AK_GRENADES;
			rn_alabel="$HDRN_AP_GRENADES";
			bool loaded=(w is "ZM66AssaultRifle")
				?!!(st&ZM66F_GRENADELOADED)
				:!!(st&LIBF_GRENADELOADED);
			int res=hpl.countinv("HDRocketAmmo");
			rn_acur=loaded?1.:-1.;
			int gshow=loaded?2:3;
			for(int i=0;i<min(gshow,res);i++)rn_aspare.push(1.);
			rn_amore=res+(loaded?1:0)>3;
			rn_atotal=res+(loaded?1:0);
			rn_aempty=!loaded;
			return true;
		}

		//magazine weapons
		rn_akind=RN_AK_MAGS;
		rn_alabel="$HDRN_AP_MAGS";
		int lcnt,lcap,lch;bool lknown,ldirty;
		[lknown,lcnt,lcap,lch,ldirty]=RN_LoadedMag(w);
		rn_acur=lcnt<0?-1.:clamp(lcnt/double(max(1,lcap)),0.,1.);
		rn_acurdirty=ldirty;
		rn_achamber=lch;
		rn_ajam=w is "ZM66AssaultRifle"&&!!(st&ZM66F_CHAMBERBROKEN);
		rn_aempty=lch!=2&&(lcnt<=0||rn_acur<=0.);

		//spares, fullest first (HD loads a full mag, or else the fullest)
		int nspare=0;
		let mm=hdmagammo(hpl.findinventory(w.hdammotype1));
		if(mm){
			nspare=mm.mags.size();
			int full=max(1,mm.GetMagHudCount(mm.maxperunit));
			array<int> cnts;
			//empty spares are left out unless the option says otherwise
			if(!rn_apshowempty)rn_apshowempty=CVar.FindCVar("hdrn_ap_showempty");
			bool showempty=rn_apshowempty&&rn_apshowempty.GetBool();
			for(int i=0;i<mm.mags.size();i++){
				int c=mm.GetMagHudCount(mm.mags[i]);
				if(c>0||showempty)cnts.push(c);
			}
			nspare=cnts.size();
			//up to 3 mags drawn: the one in the gun + 2 spares, or 3 spares
			//when the gun has no mag (its slot stays as an empty outline)
			int nshow=lcnt>=0?2:3;
			for(int k=0;k<nshow&&cnts.size()>0;k++){
				int bi=0;
				for(int i=1;i<cnts.size();i++)if(cnts[i]>cnts[bi])bi=i;
				rn_aspare.push(clamp(cnts[bi]/double(full),0.,1.));
				cnts.delete(bi);
			}
		}
		rn_atotal=nspare+(lcnt>=0?1:0);
		rn_amore=rn_atotal>3;

		//fire modes, slots top->bottom
		if(w is "HDPistol"){
			if(st&PISF_SELECTFIRE)RN_SetFM(RN_FM_AUTO,RN_FM_NONE,RN_FM_SEMI,(st&PISF_FIREMODE)?0:2);
		}else if(w is "HDSMG"){
			int sw=w.weaponstatus[SMGS_SWITCHTYPE];
			int aut=w.weaponstatus[SMGS_AUTO];	//0 semi, 1 burst, 2 auto
			int sel=aut>=2?0:aut==1?1:2;
			if(sw==0)RN_SetFM(RN_FM_AUTO,RN_FM_BURST,RN_FM_SEMI,sel);
			else if(sw==2)RN_SetFM(RN_FM_NONE,RN_FM_BURST,RN_FM_SEMI,sel);
			else if(sw==3)RN_SetFM(RN_FM_AUTO,RN_FM_NONE,RN_FM_SEMI,sel);
		}else if(w is "ZM66AssaultRifle"){
			if(!(st&ZM66F_NOFIRESELECT)){
				int aut=w.weaponstatus[ZM66S_AUTO];	//0 semi, 1 auto, 2 burst
				RN_SetFM(RN_FM_AUTO,RN_FM_BURST,RN_FM_SEMI,aut==1?0:aut>=2?1:2);
			}
		}else if(w is "LiberatorRifle"){
			if(!(st&LIBF_NOAUTO))RN_SetFM(RN_FM_AUTO,RN_FM_NONE,RN_FM_SEMI,(st&LIBF_FULLAUTO)?0:2);
		}
		return true;
	}


	// ------------------------------------------------------------
	// drawing helpers
	// ------------------------------------------------------------
	//HUD text adds 1 unscaled unit before each character; these helpers
	//take that into account so text lines up exactly
	double RN_TextW(string t,double s){
		//the engine's +1 per glyph is undone after each glyph, so it's just the scaled width
		return NewSmallFont.StringWidth(t)*s;
	}
	void RN_TextAt(string t,double x,double y,double s,int col,double alf,int fl){
		drawstring(pnewsmallfont,t,(x-1,y),fl|DI_TEXT_ALIGN_LEFT,col,alf,scale:(s,s));
	}
	void RN_TextRightAt(string t,double rx,double y,double s,int col,double alf,int fl){
		RN_TextAt(t,rx-RN_TextW(t,s),y,s,col,alf,fl);
	}

	//horizontal gradient box: transparent on the left, darker to the right
	void RN_GradBox(double x,double y,double w,double h,double alf,int fl,double maxa=0.6){
		int strips=16;
		double sw=w/strips;
		for(int i=0;i<strips;i++){
			double a=maxa*((i+1.)/strips);
			fill(color(int(255*a*alf),20,23,30),x+i*sw,y,sw+0.05,h,fl);
		}
	}

	//on/off every 0.3 s (21 tics a full cycle)
	bool RN_BlinkPhase(){
		return (gametic%21)<11;
	}

	//one mag icon: fill bottom-up, or dotted red blinking outline when empty
	void RN_MagIcon(double x,double y,double frac,bool dirty,double alf,int fl,bool spare=false){
		vector2 sc=(0.25,0.25);
		int ifl=fl|DI_ITEM_LEFT_TOP;
		//empty: dotted outline switching red / white every 0.3 s;
		//no mag at all (taken out during a reload): white / faint white
		if(frac<=0.&&spare){
			//empty spare: plain dotted white, no blinking
			DrawImage("HRNIRD",(x,y),ifl,alf*0.8,scale:sc,col:color(255,235,235,235));
			return;
		}
		if(frac<=0.){
			bool ph=RN_BlinkPhase();
			if(frac<0.)DrawImage("HRNIRD",(x,y),ifl,alf*(ph?1.:0.3),scale:sc,col:color(255,235,235,235));
			else DrawImage("HRNIRD",(x,y),ifl,alf,scale:sc,col:ph?color(255,220,50,40):color(255,235,235,235));
			return;
		}
		DrawImage("HRNIRF",(x,y),ifl,alf*0.35,scale:sc,col:color(255,18,18,18));
		if(dirty){
			double pulse=0.05+0.95*(0.5+0.5*sin(gametic*6.));
			DrawImage("HRNIRF",(x,y),ifl,alf,scale:sc,col:color(255,34,11,11));
			DrawImage("HRNIRX",(x,y),ifl,alf*pulse,scale:sc);
			DrawImage("HRNIRO",(x,y),ifl,alf,scale:sc,col:color(255,225,60,50));
			return;
		}
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		double inner=10.;		//interior height (texture rows 6..46 px = 1.5..11.5 units)
		double top=y+1.5+inner*(1.-frac);
		SetClipRect(x,top,7,y+13-top,fl);
		DrawImage("HRNIRF",(x,y),ifl,alf*0.85,scale:sc,col:RN_AmmoFill());
		screen.SetClipRect(cx,cy,cw,ch);
		DrawImage("HRNIRO",(x,y),ifl,alf,scale:sc,col:RN_AmmoLine());
	}

	//grenade icon (launcher): full, or dotted-looking blinking red when empty
	void RN_GrenIcon(double x,double y,bool loaded,double alf,int fl){
		vector2 sc=(0.25,0.25);
		int ifl=fl|DI_ITEM_LEFT_TOP;
		if(!loaded){
			DrawImage("HRNGRNO",(x,y),ifl,alf,scale:sc,col:RN_BlinkPhase()?color(255,220,50,40):color(255,235,235,235));
			return;
		}
		DrawImage("HRNGRNF",(x,y),ifl,alf*0.85,scale:sc,col:RN_AmmoFill());
		DrawImage("HRNGRNO",(x,y),ifl,alf,scale:sc,col:RN_AmmoLine());
	}

	//fire mode icon in a slot (bullets pointing right)
	void RN_FMIcon(int mode,double cx,double cy,double alf,int fl){
		color c=color(int(255*alf),235,235,235);
		double bw=2.8,bh=0.8;
		if(mode==RN_FM_SEMI){
			fill(c,cx-bw*0.5,cy-bh*0.5,bw,bh,fl);
		}else if(mode==RN_FM_BURST){
			for(int i=0;i<3;i++)fill(c,cx-2.3+i*0.9,cy-2.+i*1.6,bw,bh,fl);
		}else if(mode==RN_FM_AUTO){
			for(int i=0;i<5;i++)fill(c,cx-2.6+(i%2)*2.,cy-2.6+i*1.2,bw*0.85,bh*0.9,fl);
		}else if(mode==RN_FM_PUMP){
			double s=3./NewSmallFont.GetHeight();
			string t=StringTable.Localize("$HDRN_AP_PUMP");
			RN_TextAt(t,cx-RN_TextW(t,s)*0.5,cy-1.5,s,Font.CR_WHITE,alf,fl);
		}
	}


	// ------------------------------------------------------------
	// draw
	// ------------------------------------------------------------
	void RN_DrawAmmoPanel(){
		let w=RN_DispWeapon();
		double maxalf=max(rn_apalf,max(rn_fmalf,rn_wlalf));
		if(maxalf<=0.)return;
		bool have=RN_BuildPanel(w);
		int fl=DI_SCREEN_RIGHT_BOTTOM;

		double fh=NewSmallFont.GetHeight();
		double lblS=5.5/fh,numS=12./fh,smlS=8./fh;
		double boxh=30.,bottom=-4.;
		double top=bottom-boxh;

		//fire mode column (reserves its space whenever the weapon has modes)
		double colw=(boxh-2.)/3.;	//square slots (3 per column, 1 unit apart)
		double boxr=-4.;
		if(have&&rn_ahasfm&&rn_akind!=RN_AK_GRENADES){
			double colx=-4.-colw;
			boxr=colx-1.5;
			if(rn_fmalf>0.){
				double a=rn_fmalf;
				//stack the weapon's modes from the top, blanks at the bottom
				array<int> modes;
				int nm=0,selk=-1;
				for(int k=0;k<3;k++){
					if(rn_afm[k]==RN_FM_NONE)continue;
					if(k==rn_afmsel)selk=nm;
					modes.push(rn_afm[k]);
					nm++;
				}
				double sgap=1.;
				double slh=(boxh-sgap*2)/3.;
				for(int k=0;k<nm;k++){
					int m=modes[k];
					double sy=top+k*(slh+sgap);
					bool sel=k==selk;
					if(sel){
						fill(color(int(200*a),120,118,110),colx,sy,colw,slh,fl);
						color bc=color(int(255*a),235,235,235);
						fill(bc,colx+0.5,sy+0.5,2.,0.5,fl);
						fill(bc,colx+0.5,sy+0.5,0.5,2.,fl);
						fill(bc,colx+colw-2.5,sy+slh-1.,2.,0.5,fl);
						fill(bc,colx+colw-1.,sy+slh-2.5,0.5,2.,fl);
					}else{
						fill(color(int(170*a),20,23,30),colx,sy,colw,slh,fl);
					}
					RN_FMIcon(m,colx+colw*0.5,sy+slh*0.5,a*(sel?1.:0.35),fl);
				}
			}
		}

		//weapon list (on weapon switch), above the panel
		if(rn_wlalf>0.)RN_DrawWeaponList(top-3.,rn_wlalf,fl);

		if(!have||rn_apalf<=0.)return;
		double a=rn_apalf;

		//contents, laid out right to left from the box's right edge
		double pad=3.;
		double rx=boxr-pad;
		double numy=bottom-pad-12.;
		string lbl=StringTable.Localize(rn_alabel);

		//fixed-size background: contents that don't fit just spill out to the left
		double boxw=46.;
		RN_GradBox(boxr-boxw,top,boxw,boxh,a,fl);

		//label
		RN_TextRightAt(lbl,rx,top+2.5,lblS,Font.CR_WHITE,a,fl);

		if(rn_akind==RN_AK_COUNT){
			RN_TextRightAt(FormatNumber(rn_atotal),rx,numy,numS,rn_atotal<=0?Font.CR_RED:Font.CR_WHITE,a,fl);
			return;
		}

		if(rn_akind==RN_AK_SHELLS){
			//reserve | side saddles + in the gun
			string tin=FormatNumber(rn_aingun);
			double win=RN_TextW(tin,numS);
			double inalf=a;
			int incol=rn_aingun<=0?Font.CR_RED:Font.CR_WHITE;
			if(rn_ajam){
				incol=Font.CR_RED;
				inalf=a*(0.45+0.55*(0.5+0.5*sin(gametic*6.)));
			}
			RN_TextRightAt(tin,rx,numy,numS,incol,inalf,fl);

			//chamber bar above the in-gun number, always the same size
			//(right-aligned with it): long part = live round, short part =
			//anything in the chamber (live or spent)
			double bary=numy-2.2;
			double barw=8.;
			if(rn_acyl.size()>0){
				//revolver: the number is enough, no bar
			}else if(rn_adouble){
				//double barrel: one half per barrel (bright = live, dim = spent, faint = empty)
				double hw=(barw-1)*0.5;
				double bx=rx-barw;
				fill(color(int(255*a*(rn_achamber==2?1.:rn_achamber==1?0.45:0.15)),235,235,235),bx,bary,hw,0.8,fl);
				fill(color(int(255*a*(rn_achamber2==2?1.:rn_achamber2==1?0.45:0.15)),235,235,235),bx+hw+1,bary,hw,0.8,fl);
			}else{
				double longw=(barw-1)*0.65,shortw=(barw-1)*0.35;
				double bx=rx-barw;
				if(rn_ajam){
					color jc=RN_BlinkPhase()?color(int(255*a),220,50,40):color(int(255*a),235,235,235);
					fill(jc,bx,bary,longw,0.8,fl);
					fill(jc,bx+longw+1,bary,shortw,0.8,fl);
				}else{
					fill(color(int(255*a*(rn_achamber==2?1.:0.22)),235,235,235),bx,bary,longw,0.8,fl);
					fill(color(int(255*a*(rn_achamber>=1?1.:0.22)),235,235,235),bx+longw+1,bary,shortw,0.8,fl);
				}
			}

			double x=rx-win-1.5;
			//small numbers sit on the same baseline as the big one
			//(digits end about 74% down the font's height)
			double smy=numy+(numS-smlS)*fh*0.74;
			if(rn_asad>=0){
				RN_TextRightAt("+",x,smy,smlS,Font.CR_WHITE,a*0.8,fl);
				x-=RN_TextW("+",smlS)+1;
				string tsad=FormatNumber(rn_asad);
				RN_TextRightAt(tsad,x,smy,smlS,Font.CR_GRAY,a*0.8,fl);
				x-=RN_TextW(tsad,smlS)+2;
			}else x-=1;
			fill(color(int(140*a),235,235,235),x-0.4,smy+1.,0.6,5.,fl);
			x-=2.5;
			RN_TextRightAt(FormatNumber(rn_ares),x,smy,smlS,Font.CR_GRAY,a*0.7,fl);
			return;
		}

		//mags (or grenades): total number on the right, icons to its left
		//(the total and the "+" only when there are more than 3)
		double x=rx;
		if(rn_atotal>3){
			string tn=FormatNumber(rn_atotal);
			RN_TextRightAt(tn,rx,numy,numS,Font.CR_WHITE,a,fl);
			x=rx-RN_TextW(tn,numS)-4;
		}
		double icony=bottom-pad-13.;		//icon textures are 7x13 units

		//the one in the gun (rightmost) + its chamber bar
		x-=7;
		if(rn_akind==RN_AK_GRENADES){
			RN_GrenIcon(x+0.5,icony,rn_acur>0.,a,fl);
		}else{
			RN_MagIcon(x,icony,rn_acur,rn_acurdirty,a,fl);
			//jammed: the chamber bar switches white / red like an empty mag
			color chc=color(int(255*a*(rn_achamber==2?1.:0.22)),235,235,235);
			if(rn_ajam)chc=RN_BlinkPhase()?color(int(255*a),220,50,40):color(int(255*a),235,235,235);
			fill(chc,x+0.5,icony-1.,6,0.8,fl);
		}
		//spares, right to left
		for(int i=0;i<rn_aspare.size();i++){
			x-=7;
			if(rn_akind==RN_AK_GRENADES)RN_GrenIcon(x+0.5,icony,true,a,fl);
			else RN_MagIcon(x,icony,rn_aspare[i],false,a,fl,true);
		}
		if(rn_amore){
			RN_TextRightAt("+",x,bottom-pad-8.,smlS,Font.CR_WHITE,a,fl);
		}
	}


	// ------------------------------------------------------------
	// weapon list (shown on weapon switch)
	// ------------------------------------------------------------
	void RN_DrawWeaponList(double bottomy,double a,int fl){
		array<HDWeapon> list;
		bool hasgren=false;
		//slots 1..9, then 0; inside a slot, the engine's own order, so the
		//list matches next/previous weapon (mouse wheel) - and since "next"
		//wraps from 9 to 0 to 1, slot 0 at the bottom keeps that consistent
		for(int s=1;s<=10;s++){
			int slot=s%10;
			int sz=cplayer.weapons.SlotSize(slot);
			for(int j=0;j<sz;j++){
				let cls=cplayer.weapons.GetWeapon(slot,j);
				if(!cls)continue;
				let wp=hdweapon(cplayer.mo.FindInventory(cls));
				if(!wp||wp is "NullWeapon")continue;
				//grenades: one entry only, whatever kinds there are
				bool gren=wp is "HDGrenadeThrower";
				if(gren){
					if(hasgren)continue;
					hasgren=true;
				}else if(wp.bwimpy_weapon)continue;
				if(list.find(wp)<list.size())continue;
				list.push(wp);
			}
		}
		int n=list.size();
		if(!n)return;

		double fh=NewSmallFont.GetHeight();
		double ts=4.8/fh;
		double rowh=8.,gap=1.,roww=78.;
		double right=-4.;
		for(int i=0;i<n;i++){
			let wp=list[i];
			double y=bottomy-(n-i)*(rowh+gap);
			//while switching, only the weapon being switched to is highlighted
			bool cur=wp==rn_realwep;
			if(cur)fill(color(int(170*a),90,95,105),right-roww,y,roww,rowh,fl);
			else RN_GradBox(right-roww,y,roww,rowh,a,fl,0.5);

			//slot number box
			double sb=6.;
			double sx=right-1-sb,sy=y+1;
			//frame + interior side by side (not stacked), so nothing shows
			//through while it fades out
			color fc=color(int(200*a),235,235,235);
			fill(fc,sx,sy,sb,0.5,fl);
			fill(fc,sx,sy+sb-0.5,sb,0.5,fl);
			fill(fc,sx,sy+0.5,0.5,sb-1,fl);
			fill(fc,sx+sb-0.5,sy+0.5,0.5,sb-1,fl);
			fill(color(int(200*a),20,23,30),sx+0.5,sy+0.5,sb-1,sb-1,fl);
			string sn=FormatNumber(wp.slotnumber);
			double sns=4./fh;
			RN_TextAt(sn,sx+sb*0.5-RN_TextW(sn,sns)*0.5,sy+1,sns,Font.CR_WHITE,a,fl);

			//pickup sprite, fitted in a small box
			string spr;double sscl;
			[spr,sscl]=wp.getpickupsprite(true);
			double ix=sx-2;
			if(spr!=""){
				//flat white silhouette (stencil)
				DrawImage(spr,(ix,y+rowh*0.5),fl|DI_ITEM_RIGHT|DI_ITEM_VCENTER,a*(cur?1.:0.6),box:(16,6),
					style:STYLE_TranslucentStencil,col:color(255,235,235,235));
				ix-=18;
			}

			//name (+ how many, for grenades)
			string nm=wp.GetTag();
			let gw=HDGrenadeThrower(wp);
			if(gw&&gw.grenadeammotype)nm=nm.." x"..hpl.countinv(gw.grenadeammotype);
			RN_TextRightAt(nm,ix,y+1.6,ts,cur?Font.CR_WHITE:Font.CR_GRAY,a*(cur?1.:0.75),fl);
		}
	}
}
