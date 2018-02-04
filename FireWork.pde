
import peasy.PeasyCam;
PeasyCam camera;

PVector acceleration;

PVector shootVelocity;
PVector shootPosition;
float shootLifetime;
float MAX_SHOOT_LIFE;
float shootLifeDecay;

ArrayList<PVector> explodeVelocity;
ArrayList<PVector> explodePosition;
float explosionLifetime;
PVector explosionColor;
float MAX_EXPLODE_LIFE;
float explodeLifeDecay;
float explosionCount;

ArrayList<PVector> smokeVel;
ArrayList<PVector> smokePos;
ArrayList<Float> smokeLife;
float MAX_SMOKE_LIFE;
float smokeLifeDecay;

float SCENE_SIZE;
float sampleRadius;

float render_x, render_y, render_z;

float startTime;
float elapsedTime;

//Initialization
void setup(){
  size(1024, 960, P3D);
  
  acceleration = new PVector(0, 9.8, 0);
  explodeVelocity = new ArrayList<PVector>();
  explodePosition = new ArrayList<PVector>();
  
  MAX_EXPLODE_LIFE = 2.9;
  explodeLifeDecay = 255.0 / MAX_EXPLODE_LIFE;
  explosionCount = 4000;
  
  MAX_SHOOT_LIFE = 3;
  shootLifeDecay = 255.0 / MAX_SHOOT_LIFE;
  
  smokeVel = new ArrayList<PVector>();
  smokePos = new ArrayList<PVector>();
  smokeLife = new ArrayList<Float>();
  MAX_SMOKE_LIFE = 10;
  smokeLifeDecay = 255.0 / MAX_SMOKE_LIFE;
  
  sampleRadius = 1;
  
  SCENE_SIZE = 200;
  render_x = 0;
  render_y = 0;
  render_z = 0;
  
  float cameraZ = ((SCENE_SIZE-2.0) / tan(PI*60.0 / 360.0));
  perspective(PI/3.0, 1, 0.1, cameraZ*10.0);
  
  camera = new PeasyCam(this, SCENE_SIZE/2, SCENE_SIZE/2, (SCENE_SIZE/2.0) / tan (PI*30.0 / 180.0), 400);
  camera.setSuppressRollRotationMode();
  
  Shoot();  //get our first ball ready
  
  fill(172);
  stroke(0, 172, 255);
  
  startTime = millis();
}


//Called every frame
void draw(){
  background(0);
  
  TimeStep();
  Update(elapsedTime/1000.0);
  UserInput();
  Simulate();
}

//calculate how far to move balls
void TimeStep(){
  elapsedTime = millis() - startTime;
  startTime = millis();
}


//calculate how far to move points
void Update(float dt){
  float slowDown = 0.6;
  
  shootPosition.x += shootVelocity.x * dt;
  shootPosition.y += shootVelocity.y * dt;
  shootPosition.z += shootVelocity.z * dt;
  
  shootVelocity.y += acceleration.y * dt;
  
  shootLifetime -= dt;
  
  for(int i = 0; i < explodePosition.size(); i++){
    explodePosition.get(i).x += explodeVelocity.get(i).x * dt;
    explodePosition.get(i).y += explodeVelocity.get(i).y * dt;
    explodePosition.get(i).z += explodeVelocity.get(i).z * dt;
  
    explodeVelocity.get(i).y += acceleration.y * dt;
  }
  explosionLifetime -= dt;
  
  if(smokePos.size() > 0) {
    for(int i = smokePos.size() - 1; i > 0; i--) {
        
      smokePos.get(i).x += smokeVel.get(i).x * dt;
      smokePos.get(i).y += smokeVel.get(i).y * dt;
      smokePos.get(i).z += smokeVel.get(i).z * dt;

      smokeVel.get(i).x *= 0.985;
      smokeVel.get(i).y *= 0.985;
      smokeVel.get(i).z *= 0.985;
      
      smokeLife.set(i, smokeLife.get(i) - dt);
    }
  } 
}


//getting user input for camera
void UserInput(){
  if(keyPressed){
    if(key == 'w'){
        render_z += 1;
    }
    if(key == 's'){
        render_z -=1;
    }
    if(key == 'a'){
       render_x +=1;
    }
    if(key =='d'){
        render_x -=1;
    }
  }
}


//render the entire scene
void Simulate(){
  translateFromCamera();
  setupScene();  // setup lights and floor
  if(shootLifetime < 0) {
    Explode();
    Shoot();
    SpawnSmoke(explodePosition, explodeVelocity);
  }
  if(explodePosition.size() > 0) {
    renderExplosion();  // transpose stores points, including our new ball
  }
  renderShot();
  renderSmoke();  
  println("Framerate: " + frameRate);
  println("Number of Prticles: " + (smokePos.size() + explodePosition.size()+ 1));
}



/*  ~  HELPER FUNCTIONS  ~  */



void translateFromCamera() {
  translate(render_x, 0, render_z);
}

void renderExplosion() {
  if(explosionLifetime < 0) {
    explodePosition = new ArrayList<PVector>();
    explodeVelocity = new ArrayList<PVector>();
  } else {
    strokeWeight(explosionLifetime * explodeLifeDecay / 51);
    for(int i = explodePosition.size() - 1; i >= 0; i--){
      if(random(1) > .1) {
        stroke(explosionColor.x + random(-30, 30), explosionColor.y + random(-30, 30), explosionColor.z + random (-30, 30));
      } else {
        stroke(255, 255, 255);
      }
      //moving to new position
      point(explodePosition.get(i).x, explodePosition.get(i).y, explodePosition.get(i).z);  
    }
  }
}

void renderShot() {
  stroke(255, 255, 255);
  strokeWeight(shootLifetime * shootLifeDecay / 51);
  
  point(shootPosition.x, shootPosition.y, shootPosition.z);
}

void Shoot() {
  shootLifetime = MAX_SHOOT_LIFE;
  shootVelocity = new PVector(random(-20, 20), random(-100, -50), random(-20, 20));
  shootPosition = new PVector(SCENE_SIZE/2, SCENE_SIZE, SCENE_SIZE/2);
}

void Explode() {
  //color over time
  explosionColor = new PVector(random(0, 255), random(0, 255), random(0, 255));
  explosionLifetime = MAX_EXPLODE_LIFE;;
  
  for(int i = 0; i < explosionCount; i++) {
    float r = sampleRadius * sqrt(random(.8, 1));
    float vector = 8 * r;
    float p = sq(r) + sq(vector);
    
    float theta = 2 * PI * random(0, 1);
    float phi = 2 * PI * random(0, 1);
    explodeVelocity.add(new PVector(p * sin(phi) * cos(theta), p * sin(phi) * sin(theta), p * cos(phi)));
    explodePosition.add(new PVector(shootPosition.x, shootPosition.y, shootPosition.z));
  }
}

void renderSmoke() {
  for(int i = smokePos.size() - 1; i >= 0; i--){
      
  //color over time
  stroke(random(95, 105), random(95, 105), random(95, 15), 75);
  strokeWeight(smokeLife.get(i) * smokeLifeDecay / 30);
  
  //moving to new position
  point(smokePos.get(i).x, smokePos.get(i).y, smokePos.get(i).z); 
  
  //if point has been there too long, kill it before we move it
    if(smokeLife.get(i) < 0){
      smokePos.remove(i);
      smokeVel.remove(i);
      smokeLife.remove(i);
    }  
  }
}

void SpawnSmoke(ArrayList<PVector> pos, ArrayList<PVector> vel) {
  for(int i = pos.size() - 1; i > 0; i--) {
    smokePos.add(new PVector(pos.get(i).x, pos.get(i).y, pos.get(i).z));
    smokeVel.add(new PVector(vel.get(i).x, vel.get(i).y , vel.get(i).z));
    smokeLife.add(random(1, MAX_SMOKE_LIFE));
  }
}

//renders our floor
void setupScene(){
  pushMatrix();
  fill(#292900);
  noStroke();
  //floor
  translate(SCENE_SIZE/2, 1+SCENE_SIZE, SCENE_SIZE/2);
  box(SCENE_SIZE, 1, SCENE_SIZE);
  popMatrix();
}  