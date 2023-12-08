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
use <threads.scad> // https://github.com/rcolyer/threads-scad

$fn = $preview ? 32 : 96;

//rotational offset for the start of the thread. If your hood doesn't screw on straight, adjust this. Use the threadTest=true variable to create a simple tester blank to help determine this measurement without wasting too much time and filament.
threadRotation=45;
// enable this to print a "blank" test fit piece for determining the thread rotation angle for your particular lens.
threadTest=false;
// thread filter diameter of your lens.
filterD=43;
// width of the front element (piece of glass) of your lens.
frontD=25;
// length of the hood's screw thread.
filterH=2;
// focal length of your lens. Do not adjust this for full-frame equivalency - just use the raw focal length value.
focalLength=23;
// length of the lens hood.
hoodL=12;
lensRim=2;
// lightweight variant, more hollowed out.
light=true;
// include the lens designation "engraving" text.
useLabel=false;
// Crop factor of your camera's sensor or film size.
sensorCrop=1.5; //Options: FullFrame=1.0,APS-C(DX)=1.5,APS-C(Canon)=1.6,MFT=2
// Ratio of your camera's sensor. Micro Four Thirds is 4:3 as the name suggests (1.33), other cameras are generally 3:2 (1.5).
sensorRatio=1.5; //Options: FullFrame/APS-C=3/2,MFT=4/3
showFOV=$preview;
// corner radiusing.
boxRadius=3;
// use the threads.scad library. If you are using the Thingiverse customizer, turn this off.
useThreadsLib=true;

FOV=2*atan(43.27/(2*focalLength*sensorCrop));

echo(str("FOV = ",FOV));

hoodDesignation=str(focalLength,"/",filterD);

module ThreadBase(pitch=0.75,dia=52,resolution=90,height=10) {
  if (useThreadsLib) {
    ScrewThread(outer_diam=dia, height=height, pitch=pitch);
  } else {
    pitchAngle=atan(PI*dia/pitch);
    echo(str("pitchAngle=",pitchAngle,"mm"));
    difference() {
      cylinder(d=dia,h=height,$fn=resolution);
      for(i=[0:360/resolution:360-360/resolution]) {
        rotate([0,0,i]) {
          for(j=[0:pitch:height/pitch+pitch]) {
            translate([dia/2,0,pitch*i/(360-360/resolution)+j-pitch]) {
              rotate([-pitchAngle,0,0]) {
                scale([1,0.866,1]) {
                  cylinder(d=pitch,h=10,$fn=4,center=true);
                }
              }
            }
          }
        }
      }
    }
  }
}

module FOV() {
  front=frontD+(filterH+hoodL)*tan(FOV/2);
  %hull() {
    cylinder(d=frontD,h=0.1);
    translate([0,0,filterH+hoodL])
      rotate([90,0,0])
      cube([front, 1, front/sensorRatio], center=true);
  }
}

module SquareLensHood(filterD=52,frontD=40,filterH=4,FOV=50,hoodL=20,lensRim=2) {
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
      echo(str("Check Front Diameter: ",frontD,"mm"));
      roundedBox([frontD,frontD/1.5,0.2],boxRadius,sidesonly=true);
      translate([0,0,filterH+hoodL-2.99])
        roundedBox([frontSize,frontSize/1.5,3],boxRadius*frontSize/frontD,sidesonly=true);
    }

    translate([0,0,-0.01])cylinder(d=filterD-3,h=filterH/2);
    echo(str("Checking text angle:",atan(((filterD/2+lensRim)-(frontSize/1.5)/2)/hoodL)));

    if (useLabel) {
      translate([0,-filterD/2-lensRim,filterH])
        rotate([-atan(((filterD/2+lensRim)-(frontSize/1.5)/2)/hoodL),0,0])
        translate([0,0,hoodL])
        rotate([90,0,0])
        translate([0,-2,0])
        linear_extrude(2)
        text(hoodDesignation,5,halign="center",valign="top");
    }
  }

  if(showFOV) {
    FOV();
  }
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

    if(useLabel) {
      translate([0,-filterD/2-lensRim,filterH])
        rotate([-atan(((filterD/2+lensRim)-(frontSize/1.5)/2)/hoodL),0,0])
        translate([0,0,hoodL])
        rotate([90,0,0])
        translate([0,-2,0])
        linear_extrude(2)
        text(hoodDesignation,5,halign="center",valign="top");
    }
  }

  if(showFOV) {
    FOV();
  }
}

renderRotation = $preview ? [0,0,0] : [0,180,0];

rotate(renderRotation)
  if (threadTest) {
    intersection() {
      cylinder(d=filterD,h=filterH+0.2);
      SquareLensHood(filterD=filterD,frontD=frontD,filterH=filterH,FOV=FOV,hoodL=hoodL,lensRim=lensRim);
    }
  } else {
    if (light) {
      SquareLensHoodLight(filterD=filterD,frontD=frontD,filterH=filterH,FOV=FOV,hoodL=hoodL,lensRim=lensRim);
    } else {
      SquareLensHood(filterD=filterD,frontD=frontD,filterH=filterH,FOV=FOV,hoodL=hoodL,lensRim=lensRim);
    }
  }
