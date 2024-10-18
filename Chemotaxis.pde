ArrayList<Bacteria> bacs;
int INIT_BAC_COUNT = 100;  // spawn this number of bac at the beginning
double FOOD_AMOUNT = 5000;  // how much food one spot have

int foodX, foodY;
double foodLeft = 0;

int randint(int min, int max) {
    // include min, max
    int diff = Math.abs(max+1 - min);
    return (int) (Math.random() * diff) + min;
}

void setup() {
  size(400,400);
  frameRate(60);
  
  foodX = width/2;
  foodY = height/2;
  foodLeft = FOOD_AMOUNT;
  
  bacs = new ArrayList<Bacteria>();
  for (int i=0; i<INIT_BAC_COUNT; i++)
    bacs.add(new Bacteria());
}

void draw() {
  background(200);
  for (int i=0; i<bacs.size(); i++) {
    boolean canReproduce = bacs.get(i).update(foodX, foodY);
    if(canReproduce && bacs.size() < 1000) {
      bacs.add(new Bacteria());
      bacs.get(bacs.size() - 1).inherit(bacs.get(i));
    }
  }
  
  // clear all dead bacs
  for (int i=0; i<bacs.size(); i++) {
    if(bacs.get(i).isDead) {
      bacs.remove(i);
      i--;  // move one idx back because we deleted the original occupier
    }
  }
  
  double avgWeightW = 0;
  double sumWeightW = 0;
  double avgWeightS = 0;
  double sumWeightS = 0;
  double avgWillingness = 0;
  double sumWillingness = 0;
  double sumGotFood = 0;
  HashMap<Integer, Double[]> specieCount = new HashMap<Integer, Double[]>();
  
  for (int i=0; i<bacs.size(); i++) {
    sumWeightW += bacs.get(i).weightWill;
    sumWeightS += bacs.get(i).weightStrength;
    sumWillingness += bacs.get(i).willingness;
    sumGotFood += bacs.get(i).isNearFood(foodX, foodY) ? 1 : 0;
    int k = bacs.get(i).bacColor;
    if (specieCount.containsKey(k))
      // [count, weight, strength]
      specieCount.put(k, new Double[]{specieCount.get(k)[0]+1, bacs.get(i).weightWill, bacs.get(i).weightStrength});
    else
      specieCount.put(k, new Double[]{(double)1, bacs.get(i).weightWill, bacs.get(i).weightStrength});
  }
  
  int majorSpecie = 0;
  double majorSpecieWW = 0;
  double majorSpecieWS = 0;
  int majorSpecieCount = 0;
  for (Integer k : specieCount.keySet()) {
    if (specieCount.get(k)[0] > majorSpecieCount) {
      majorSpecie = k;
      majorSpecieWW = specieCount.get(k)[1];
      majorSpecieWS = specieCount.get(k)[2];
      majorSpecieCount = (int) specieCount.get(k)[0];
    }
  }
  
  avgWeightW = sumWeightW / bacs.size();
  avgWeightS = sumWeightS / bacs.size();
  avgWillingness = sumWillingness / bacs.size();
  
  // update food location
  //stroke(0,255,0);
  fill(0,255,0,100);
  ellipseMode(CENTER);
  ellipse(foodX, foodY, 50, 50);
  foodLeft -= sumGotFood;
  if (foodLeft <= 0) {
    foodLeft = FOOD_AMOUNT;
    foodX = randint(0, width);
    foodY = randint(0, height);
  }
  
  // show info
  fill(255,0,0);
  textSize(14);
  text("Average w.Will: "+avgWeightW, 5, 10);
  text("Average w.Strength: "+avgWeightS, 5, 25);
  text("Average Willingness: "+avgWillingness, 5, 40);
  text("Bacteria Count: "+bacs.size(), 5, 55);
  text("Food Pos: X="+foodX+" Y="+foodY, 5, 70);
  text("Food Left: "+(foodLeft)+"/"+FOOD_AMOUNT, 5, 85);
  text("Receievd Food: "+sumGotFood+"/"+bacs.size(), 5, 100);
  text("Click screen to trigger immediate Food Respawn!", 5, 345);
  text("Species Count: "+specieCount.size(), 5, 360);
  fill(majorSpecie);
  text("Major Specie: (w.W) "+majorSpecieWW+"\n(w.S) "+majorSpecieWS+" (count) "+majorSpecieCount, 5, 375);
}

void mousePressed() {
  fill(0,255,0,100);
  ellipseMode(CENTER);
  ellipse(foodX, foodY, 50, 50);
  foodLeft = FOOD_AMOUNT;
  foodX = randint(0, width);
  foodY = randint(0, height);
}

class Bacteria {
  double x,y;
  int bacColor;  // unique id
  double weightWill;  // willingness = weight * senseConcentration
  double weightStrength;  // strength (how far can it go each step)
  int life;
  int hp;
  boolean isDead = false;
  double willingness = 0;
  
  // the most optimized will have a weight of 1, 
  // but to demonstrate the evolution, we will init it to random (0-1)
  
  // distance when senseConcentration it's at max (1);
  int MAX_SENSE_DISTANCE = (int) Math.sqrt(Math.pow(width, 2) + Math.pow(height, 2));
  double FOOD_DISTANCE_TRES = 25;  // can reproduce when distance to food is less than this
  double REPROD_RATE = 0.05;  // rate to reproduce
  double MUTATION_RATE = 0.20;  // rate to mutate
  double MUTATION_RANGE_W = 0.1;  // weightWill can change by +-0.1 when mutation happens
  double MUTATION_RANGE_S = 0.2;  // weightStrength
  int LIFE_TIME;  // how many frames can it live?
  int INIT_HP = 300;  // initial hp - if not near food it will loose hp
  
  // their offspring will inherit the color and weight of their parents.
  // mutated offspring will have a new random color and weight changed.
  
  Bacteria() {
    x = randint(0,width);
    y = randint(0,height);
    bacColor = color(randint(0,255), randint(0,255), randint(0,255));
    //bacColor = color(255, 0, 0);
    weightWill = Math.random()*0.5;
    weightStrength = rand(1,2);
		LIFE_TIME = randint(400, 500);	// class func should be called in or after constructor
    life = LIFE_TIME;
    hp = INIT_HP;
  }
  
  private color changeColorRandomly(int originalColor, double changeAmount) {  
    // RGB to HSB for easier manipulation
    double h = hue(color(originalColor));
    double s = saturation(color(originalColor));
    double br = brightness(color(originalColor));
  
    // Randomly modify the hue based on the change amount
    double hueShift = rand(-255*changeAmount, 255*changeAmount);  // Shift hue by ±changeAmount
    h = (h + hueShift) % 360;
  
    // Convert back to RGB color
    colorMode(HSB);
    color newColor = color((int)h, (int)s, (int)br);
    colorMode(RGB, 255);
    
    return newColor;
  }
  
  private int randint(int min, int max) {
    // include min, max
    int diff = Math.abs(max+1 - min);
    return (int) (Math.random() * diff) + min;
  }
  
  double rand(double min, double max) {
    // include min, max
    return min + (Math.random() * (max - min + 0.000000001));
  }
  
  private boolean isMutated() {
    return Math.random() < MUTATION_RATE;
  }
  
  private double senseConcentration(int targetX, int targetY) {
    double sc = dist((float)x, (float)y, targetX, targetY) / MAX_SENSE_DISTANCE;
    sc = 0.2*sc + 0.5;
    return sc;
  }
  
  // inherit from parent
  public void inherit(Bacteria parent) {
    if (isMutated()) {
      double mutationW = rand(-1.0 * MUTATION_RANGE_W, MUTATION_RANGE_W);
      double mutationS = rand(-1.0 * MUTATION_RANGE_S, MUTATION_RANGE_S);
      
      weightWill = parent.weightWill + mutationW;
      weightWill = weightWill >= 0 ? weightWill : 0;
      weightWill = weightWill <= 1.0 ? weightWill : 1.0;
      
      weightStrength = parent.weightStrength + mutationS;
      weightStrength = weightStrength >= 0 ? weightStrength : 0;
      //weightStrength = weightStrength <= 1.0 ? weightStrength : 1.0;
      
      // does not have to change color bc it is already random
      bacColor = changeColorRandomly(parent.bacColor, 1*((mutationW+mutationS)/2));
      return;
    }
    
    weightWill = parent.weightWill;
    weightStrength = parent.weightStrength;
    bacColor = parent.bacColor;
  }
  
  // true = move towards target, false = random
  private boolean determineMove(int targetX, int targetY) {
    // willingness = weight * senseConcentration
    
    willingness = weightWill * senseConcentration(targetX, targetY);
    // probably not needed but just to be safe
    willingness = willingness >= 0 ? willingness : 0;
    willingness = willingness <= 1 ? willingness : 1;
    
    return Math.random() < willingness ? true : false;
  }
  
  private void move(int targetX, int targetY) {
    if (!determineMove(targetX, targetY)) {
      x += randint(-2,2);
      y += randint(-2,2);
      return;
    }
    
    double dX, dY;
    dX = x < targetX ? weightStrength : -weightStrength;
    //dX -= x > targetX ? 2 : 0;
    dY = y < targetY ? weightStrength : -weightStrength;
    //dY -= y > targetY ? 2 : 0;
    
    x += dX;
    y += dY;
  }
  
   private boolean isNearFood(int targetX, int targetY) {
    double distance = dist((float)x, (float)y, targetX, targetY);
    return distance < FOOD_DISTANCE_TRES;
  }
  
  private boolean approveReproduce(int targetX, int targetY) {
    if (isNearFood(targetX, targetY))
      return Math.random() < REPROD_RATE;
    return false;
  }
  
  private void healOrDamage(int targetX, int targetY) {
    if (isNearFood(targetX, targetY))
      hp += 1.5;
    else
      hp -= 1;
  }
  
  private void display() {
    fill(bacColor);
    ellipseMode(CENTER);
    ellipse((int)x, (int)y, 10, 10);
  }
  
  // update, return if reproduce
  public boolean update(int targetX, int targetY) {
    move(targetX, targetY);
    display();
    healOrDamage(targetX, targetY);
    life -= 1;
    isDead = ( life <= 0 || hp <= 0 ) ? true : false;
    return approveReproduce(targetX, targetY);
  }
}
