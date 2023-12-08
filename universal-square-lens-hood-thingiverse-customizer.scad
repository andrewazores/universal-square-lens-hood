/*
 * This lens hood was designed by https://www.thingiverse.com/anexperilog aka Thorben Mense.
 * It comes with the CC-BY-SA Licence, so please stick to it.
 * Have fun with the design!
 *
 * ----
 *
 * Forked and modified by Andrew Azores: https://github.com/andrewazores/universal-square-lens-hood
 * Originally found at https://www.thingiverse.com/thing:4921955
 */

use <MCAD/boxes.scad>

$fn = $preview ? 32 : 96;

//rotational offset for the start of the thread. If your hood doesn't screw on straight, adjust this.
threadRotation=0;
// thread filter diameter of your lens.
filterD=52;
// width of the front element (piece of glass) of your lens.
frontD=25;
// length of the hood's screw thread.
filterH=2.5;
// focal length of your lens. Do not adjust this for full-frame equivalency - just use the raw focal length value. To be safe, set this to slightly less than your lens' actual focal length, to avoid vignetting.
focalLength=40;
// length of the lens hood.
hoodL=16;
lensRim=2;
// Crop factor of your camera's sensor or film size.
sensorCrop=1.5; //Options: FullFrame=1.0,APS-C(DX)=1.5,APS-C(Canon)=1.6,MFT=2
// Ratio of your camera's sensor. Micro Four Thirds is 4:3 as the name suggests (1.33), other cameras are generally 3:2 (1.5).
sensorRatio=1.5; //Options: FullFrame/APS-C=3/2,MFT=4/3
// corner radiusing.
boxRadius=3;

FOV=2*atan(43.27/(2*focalLength*sensorCrop));

echo(str("FOV = ",FOV));

hoodDesignation=str(focalLength,"/",filterD);

screw_resolution = 0.2;  // in mm

module ClosePoints(pointarrays) {
  function recurse_avg(arr, n=0, p=[0,0,0]) = (n>=len(arr)) ? p :
    recurse_avg(arr, n+1, p+(arr[n]-p)/(n+1));

  N = len(pointarrays);
  P = len(pointarrays[0]);
  NP = N*P;
  lastarr = pointarrays[N-1];
  midbot = recurse_avg(pointarrays[0]);
  midtop = recurse_avg(pointarrays[N-1]);

  faces_bot = [
    for (i=[0:P-1])
      [0,i+1,1+(i+1)%len(pointarrays[0])]
  ];

  loop_offset = 1;
  bot_len = loop_offset + P;

  faces_loop = [
    for (j=[0:N-2], i=[0:P-1], t=[0:1])
      [loop_offset, loop_offset, loop_offset] + (t==0 ?
      [j*P+i, (j+1)*P+i, (j+1)*P+(i+1)%P] :
      [j*P+i, (j+1)*P+(i+1)%P, j*P+(i+1)%P])
  ];

  top_offset = loop_offset + NP - P;
  midtop_offset = top_offset + P;

  faces_top = [
    for (i=[0:P-1])
      [midtop_offset,top_offset+(i+1)%P,top_offset+i]
  ];

  points = [
    for (i=[-1:NP])
      (i<0) ? midbot :
      ((i==NP) ? midtop :
      pointarrays[floor(i/P)][i%P])
  ];
  faces = concat(faces_bot, faces_loop, faces_top);

  polyhedron(points=points, faces=faces);
}

module ScrewThread(outer_diam, height, pitch=0, tooth_angle=30, tolerance=0.4, tip_height=0, tooth_height=0, tip_min_fract=0) {

  pitch = (pitch==0) ? ThreadPitch(outer_diam) : pitch;
  tooth_height = (tooth_height==0) ? pitch : tooth_height;
  tip_min_fract = (tip_min_fract<0) ? 0 :
    ((tip_min_fract>0.9999) ? 0.9999 : tip_min_fract);

  outer_diam_cor = outer_diam + 0.25*tolerance; // Plastic shrinkage correction
  inner_diam = outer_diam - tooth_height/tan(tooth_angle);
  or = (outer_diam_cor < screw_resolution) ?
    screw_resolution/2 : outer_diam_cor / 2;
  ir = (inner_diam < screw_resolution) ? screw_resolution/2 : inner_diam / 2;
  height = (height < screw_resolution) ? screw_resolution : height;

  steps_per_loop_try = ceil(2*3.14159265359*or / screw_resolution);
  steps_per_loop = (steps_per_loop_try < 4) ? 4 : steps_per_loop_try;
  hs_ext = 3;
  hsteps = ceil(3 * height / pitch) + 2*hs_ext;

  extent = or - ir;

  tip_start = height-tip_height;
  tip_height_sc = tip_height / (1-tip_min_fract);

  tip_height_ir = (tip_height_sc > tooth_height/2) ?
    tip_height_sc - tooth_height/2 : tip_height_sc;

  tip_height_w = (tip_height_sc > tooth_height) ? tooth_height : tip_height_sc;
  tip_wstart = height + tip_height_sc - tip_height - tip_height_w;


  function tooth_width(a, h, pitch, tooth_height, extent) =
    let(
      ang_full = h*360.0/pitch-a,
      ang_pn = atan2(sin(ang_full), cos(ang_full)),
      ang = ang_pn < 0 ? ang_pn+360 : ang_pn,
      frac = ang/360,
      tfrac_half = tooth_height / (2*pitch),
      tfrac_cut = 2*tfrac_half
    )
    (frac > tfrac_cut) ? 0 : (
      (frac <= tfrac_half) ?
        ((frac / tfrac_half) * extent) :
        ((1 - (frac - tfrac_half)/tfrac_half) * extent)
    );


  pointarrays = [
    for (hs=[0:hsteps])
      [
        for (s=[0:steps_per_loop-1])
          let(
            ang_full = s*360.0/steps_per_loop,
            ang_pn = atan2(sin(ang_full), cos(ang_full)),
            ang = ang_pn < 0 ? ang_pn+360 : ang_pn,

            h_fudge = pitch*0.001,

            h_mod =
              (hs%3 == 2) ?
                ((s == steps_per_loop-1) ? tooth_height - h_fudge : (
                 (s == steps_per_loop-2) ? tooth_height/2 : 0)) : (
              (hs%3 == 0) ?
                ((s == steps_per_loop-1) ? pitch-tooth_height/2 : (
                 (s == steps_per_loop-2) ? pitch-tooth_height + h_fudge : 0)) :
                ((s == steps_per_loop-1) ? pitch-tooth_height/2 + h_fudge : (
                 (s == steps_per_loop-2) ? tooth_height/2 : 0))
              ),

            h_level =
              (hs%3 == 2) ? tooth_height - h_fudge : (
              (hs%3 == 0) ? 0 : tooth_height/2),

            h_ub = floor((hs-hs_ext)/3) * pitch
              + h_level + ang*pitch/360.0 - h_mod,
            h_max = height - (hsteps-hs) * h_fudge,
            h_min = hs * h_fudge,
            h = (h_ub < h_min) ? h_min : ((h_ub > h_max) ? h_max : h_ub),

            ht = h - tip_start,
            hf_ir = ht/tip_height_ir,
            ht_w = h - tip_wstart,
            hf_w_t = ht_w/tip_height_w,
            hf_w = (hf_w_t < 0) ? 0 : ((hf_w_t > 1) ? 1 : hf_w_t),

            ext_tip = (h <= tip_wstart) ? extent : (1-hf_w) * extent,
            wnormal = tooth_width(ang, h, pitch, tooth_height, ext_tip),
            w = (h <= tip_wstart) ? wnormal :
              (1-hf_w) * wnormal +
              hf_w * (0.1*screw_resolution + (wnormal * wnormal * wnormal /
                (ext_tip*ext_tip+0.1*screw_resolution))),
            r = (ht <= 0) ? ir + w :
              ( (ht < tip_height_ir ? ((2/(1+(hf_ir*hf_ir))-1) * ir) : 0) + w)
          )
          [r*cos(ang), r*sin(ang), h]
      ]
  ];


  ClosePoints(pointarrays);
}

module ThreadBase(pitch=0.75,dia=52,resolution=90,height=10) {
  ScrewThread(outer_diam=dia, height=height, pitch=pitch);
}

module SquareLensHoodLight(filterD=52,frontD=40,filterH=4,FOV=50,hoodL=20,lensRim=2) {
  frontSize=frontD+(filterH+hoodL)*tan(FOV/2)*1.5;
  echo(str("frontSize=",frontSize,"mm"));

  difference() {
    union() {
      hull() {
        translate([0,0,filterH]) {
          cylinder(d1=filterD+lensRim*2-0.4,d2=filterD+lensRim*2,h=0.2);
        }

        translate([0,0,filterH+hoodL-3]) {
          intersection() {
            cube([frontSize+3.6,frontSize/1.5+3.6,3] ,center=true);
            cylinder(d=frontSize*1.2,h=3,center=true);
          }
        }
      }
      rotate([0,0,threadRotation])
        ThreadBase(pitch=0.75,dia=filterD,resolution=180,height=filterH);
    }

    hull() {
      translate([0,0,filterH])
        cylinder(d=filterD-3,h=0.1);
      translate([0,0,filterH+hoodL-2.99])
        roundedBox([frontSize,frontSize/1.5,3],boxRadius*frontSize/frontD,sidesonly=true);
    }

    translate([0,0,-0.01])
      cylinder(d=filterD-3,h=filterH+0.02);

    translate([0,-filterD/2-lensRim,filterH])
      rotate([-atan(((filterD/2+lensRim)-(frontSize/1.5)/2)/hoodL),0,0])
      translate([0,0,hoodL])
      rotate([90,0,0])
      translate([0,-2,0])
      linear_extrude(2)
      text(hoodDesignation,5,halign="center",valign="top");
  }
}

renderRotation = $preview ? [0,0,0] : [0,180,0];

rotate(renderRotation) {
  SquareLensHoodLight(filterD=filterD,frontD=frontD,filterH=filterH,FOV=FOV,hoodL=hoodL,lensRim=lensRim);
}
