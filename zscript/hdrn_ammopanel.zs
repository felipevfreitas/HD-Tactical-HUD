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
// only the fire mode column), fades out; firing keeps it up, and brings it
// back (fading in) if it was fading out.
// ------------------------------------------------------------
extend class HDRNStatusBar{

	enum HDRNPanelConsts{
		RN_PFADE=18,		//fade-out tics
		RN_PFADEIN=6,		//fade-in tics (when firing brings it back)
		RN_FIREHOLD=50,		//how long firing keeps it up

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
	weapon rn_lastready;

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


	// ------------------------------------------------------------
	// visibility
	// ------------------------------------------------------------
	void RN_PanelShow(bool ammo,bool fm,bool list){
		int len=int(clamp(rn_inspecttime?rn_inspecttime.GetFloat():3.,0.5,30.)*TICRATE);
		if(ammo){rn_aptimer=max(rn_aptimer,len);rn_apalf=1;}
		if(fm){rn_fmtimer=max(rn_fmtimer,len);rn_fmalf=1;}
		if(list){rn_wltimer=max(rn_wltimer,len);rn_wlalf=1;}
	}

	void RN_PanelTick(){
		//follow the existing triggers (inspect key, hold, reload, pump...)
		if(inspecttimer>rn_lastinspect+1)RN_PanelShow(true,!rn_inspectweaponly,false);
		if(inspecttimer>0){
			rn_aptimer=max(rn_aptimer,inspecttimer);
			if(!rn_inspectweaponly)rn_fmtimer=max(rn_fmtimer,inspecttimer);
		}
		rn_lastinspect=inspecttimer;

		//fire mode changed: only the fire mode column
		if(rn_modeflash==35)RN_PanelShow(false,true,false);

		//weapon switch: everything
		let rw=cplayer.readyweapon;
		if(rw!=rn_lastready||cplayer.pendingweapon!=WP_NOCHANGE){
			if(rw!=rn_lastready||rn_wltimer<=0)RN_PanelShow(true,true,true);
			rn_lastready=rw;
		}

		//firing keeps whatever is visible up (and brings back a fading one)
		if(cplayer.cmd.buttons&BT_ATTACK){
			if(rn_apalf>0)rn_aptimer=max(rn_aptimer,RN_FIREHOLD);
			if(rn_fmalf>0)rn_fmtimer=max(rn_fmtimer,RN_FIREHOLD);
		}

		if(rn_aptimer>0){rn_aptimer--;rn_apalf=min(1.,rn_apalf+1./RN_PFADEIN);}
		else rn_apalf=max(0.,rn_apalf-1./RN_PFADE);
		if(rn_fmtimer>0){rn_fmtimer--;rn_fmalf=min(1.,rn_fmalf+1./RN_PFADEIN);}
		else rn_fmalf=max(0.,rn_fmalf-1./RN_PFADE);
		if(rn_wltimer>0){rn_wltimer--;rn_wlalf=min(1.,rn_wlalf+1./RN_PFADEIN);}
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
			||w is "HDGrenadeThrower"
		);
	}

	bool RN_BuildPanel(hdweapon w){
		if(!RN_PanelWeapon(w))return false;
		rn_ahasfm=false;
		rn_afm[0]=RN_FM_NONE;rn_afm[1]=RN_FM_NONE;rn_afm[2]=RN_FM_NONE;
		rn_aspare.clear();
		rn_amore=false;rn_ajam=false;rn_apump=false;rn_acurdirty=false;
		int st=w.weaponstatus[0];

		//hand grenades: just how many are left
		if(w is "HDGrenadeThrower"){
			rn_akind=RN_AK_COUNT;
			rn_alabel="$HDRN_AP_GRENADES";
			let gw=HDGrenadeThrower(w);
			rn_atotal=gw.grenadeammotype?hpl.countinv(gw.grenadeammotype):0;
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
			if(!(st&HUNTF_EXPORT)){
				int fm=w.weaponstatus[HUNTS_FIREMODE];	//0 pump, 1 semi, 2 auto
				int sel=fm>=2?0:fm==1?1:2;
				if(st&HUNTF_CANFULLAUTO)RN_SetFM(RN_FM_AUTO,RN_FM_SEMI,RN_FM_PUMP,sel);
				else RN_SetFM(RN_FM_NONE,RN_FM_SEMI,RN_FM_PUMP,sel);
			}
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
			for(int i=0;i<min(2,res);i++)rn_aspare.push(1.);
			rn_amore=res>2;
			rn_atotal=res+(loaded?1:0);
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

		//spares, fullest first (HD loads a full mag, or else the fullest)
		int nspare=0;
		let mm=hdmagammo(hpl.findinventory(w.hdammotype1));
		if(mm){
			nspare=mm.mags.size();
			int full=max(1,mm.GetMagHudCount(mm.maxperunit));
			array<int> cnts;
			for(int i=0;i<nspare;i++)cnts.push(mm.GetMagHudCount(mm.mags[i]));
			for(int k=0;k<2&&cnts.size()>0;k++){
				int bi=0;
				for(int i=1;i<cnts.size();i++)if(cnts[i]>cnts[bi])bi=i;
				rn_aspare.push(clamp(cnts[bi]/double(full),0.,1.));
				cnts.delete(bi);
			}
		}
		rn_amore=nspare>2;
		rn_atotal=nspare+(lcnt>=0?1:0);

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
		return NewSmallFont.StringWidth(t)*s+t.CodePointCount();
	}
	void RN_TextAt(string t,double x,double y,double s,int col,double alf,int fl){
		drawstring(pnewsmallfont,t,(x-1,y),fl|DI_TEXT_ALIGN_LEFT,col,alf,scale:(s,s));
	}
	void RN_TextRightAt(string t,double rx,double y,double s,int col,double alf,int fl){
		RN_TextAt(t,rx-RN_TextW(t,s)+1,y,s,col,alf,fl);
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

	//one mag icon: fill bottom-up, or dotted red blinking outline when empty
	void RN_MagIcon(double x,double y,double frac,bool dirty,double alf,int fl){
		vector2 sc=(0.25,0.25);
		int ifl=fl|DI_ITEM_LEFT_TOP;
		if(frac<=0.){
			double blink=0.35+0.65*(0.5+0.5*sin(gametic*5.));
			DrawImage("HRNIRD",(x,y),ifl,alf*blink,scale:sc,col:color(255,220,50,40));
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
			double blink=0.35+0.65*(0.5+0.5*sin(gametic*5.));
			DrawImage("HRNGRNO",(x,y),ifl,alf*blink,scale:sc,col:color(255,220,50,40));
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
	void RN_DrawAmmoPanel2(){
		let w=hdweapon(cplayer.readyweapon);
		double maxalf=max(rn_apalf,max(rn_fmalf,rn_wlalf));
		if(maxalf<=0.)return;
		bool have=RN_BuildPanel(w);
		int fl=DI_SCREEN_RIGHT_BOTTOM;

		double fh=NewSmallFont.GetHeight();
		double lblS=5.5/fh,numS=12./fh,smlS=8./fh;
		double boxh=30.,bottom=-4.;
		double top=bottom-boxh;

		//fire mode column (reserves its space whenever the weapon has modes)
		double colw=13.;
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
			RN_TextRightAt(FormatNumber(rn_atotal),rx,numy,numS,Font.CR_WHITE,a,fl);
			return;
		}

		if(rn_akind==RN_AK_SHELLS){
			//reserve | side saddles + in the gun
			string tin=FormatNumber(rn_aingun);
			double win=RN_TextW(tin,numS);
			double inalf=a;
			int incol=Font.CR_WHITE;
			if(rn_ajam){
				incol=Font.CR_RED;
				inalf=a*(0.45+0.55*(0.5+0.5*sin(gametic*6.)));
			}
			RN_TextRightAt(tin,rx,numy,numS,incol,inalf,fl);

			//chamber bar above the in-gun number: long part = live shell,
			//short part = anything in the chamber (live or spent)
			double bary=numy-2.2;
			double longw=(win-1)*0.65,shortw=(win-1)*0.35-1;
			double bx=rx-win+1;
			fill(color(int(255*a*(rn_achamber==2?1.:0.22)),235,235,235),bx,bary,longw,0.8,fl);
			fill(color(int(255*a*(rn_achamber>=1?1.:0.22)),235,235,235),bx+longw+1,bary,shortw,0.8,fl);

			double x=rx-win-1.5;
			double smy=bottom-pad-8.;
			RN_TextRightAt("+",x,smy,smlS,Font.CR_WHITE,a*0.8,fl);
			x-=RN_TextW("+",smlS)+1;
			string tsad=FormatNumber(rn_asad);
			RN_TextRightAt(tsad,x,smy,smlS,Font.CR_GRAY,a*0.8,fl);
			x-=RN_TextW(tsad,smlS)+2;
			fill(color(int(140*a),235,235,235),x-0.4,smy+0.5,0.6,7,fl);
			x-=2.5;
			RN_TextRightAt(FormatNumber(rn_ares),x,smy,smlS,Font.CR_GRAY,a*0.7,fl);
			return;
		}

		//mags (or grenades): total number on the right, icons to its left
		string tn=FormatNumber(rn_atotal);
		RN_TextRightAt(tn,rx,numy,numS,Font.CR_WHITE,a,fl);
		double x=rx-RN_TextW(tn,numS)-4;
		double icony=bottom-pad-13.;		//icon textures are 7x13 units

		//the one in the gun (rightmost) + its chamber bar
		x-=7;
		if(rn_akind==RN_AK_GRENADES){
			RN_GrenIcon(x+0.5,icony,rn_acur>0.,a,fl);
		}else{
			RN_MagIcon(x,icony,rn_acur,rn_acurdirty,a,fl);
			fill(
				color(int(255*a*(rn_achamber==2?1.:0.22)),235,235,235),
				x+0.5,icony-1.,6,0.8,fl
			);
		}
		//spares, right to left
		for(int i=0;i<rn_aspare.size();i++){
			x-=7;
			if(rn_akind==RN_AK_GRENADES)RN_GrenIcon(x+0.5,icony,true,a,fl);
			else RN_MagIcon(x,icony,rn_aspare[i],false,a,fl);
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
		//slots 1..9, then 0
		for(int s=1;s<=10;s++){
			int slot=s%10;
			for(let item=cplayer.mo.inv;item!=null;item=item.inv){
				let wp=hdweapon(item);
				if(!wp||wp.bwimpy_weapon||wp.slotnumber!=slot)continue;
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
			bool cur=cplayer.pendingweapon!=WP_NOCHANGE?
				wp==cplayer.pendingweapon:wp==cplayer.readyweapon;
			if(cur)fill(color(int(170*a),90,95,105),right-roww,y,roww,rowh,fl);
			else RN_GradBox(right-roww,y,roww,rowh,a,fl,0.5);

			//slot number box
			double sb=6.;
			double sx=right-1-sb,sy=y+1;
			fill(color(int(200*a),235,235,235),sx,sy,sb,sb,fl);
			fill(color(int(255*a),20,23,30),sx+0.5,sy+0.5,sb-1,sb-1,fl);
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
					style:STYLE_Stencil,col:color(255,235,235,235));
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
