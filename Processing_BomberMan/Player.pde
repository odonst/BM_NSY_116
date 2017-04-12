



public class BomberMan {
  private ArrayList<PImage> lPlayerImages  = new ArrayList<PImage>();
  private int spriteWidth = 16;
  private int SpriteHeight = 32;
  private int totalSprite = 134;
  // private boolean playerControl = false;
  //private ArrayList<SpriteAnimation> lAnimation;
  private EnumMap<Action, SpriteAnimation> lAnimation = new EnumMap<Action, SpriteAnimation>(Action.class);
  
  private Action previousAction = Action.LOOK_FRONT_WAIT; // par défaut
  private int frameCounter = 0;
  public int  blockPosition;
  private Map map;
  private boolean bControl;
  private Rect rect = new Rect();
  private int walkSpeed;
  private Sprite spriteToRender;
  public BomberMan(PImage tileMapImg, Map map, int SpawnPosition, int pxTileSize) {

    this.map = map; // on garde une référence de l'objet map sur lequel le joueur est censé interagir..
    
    int TilePerWidth = tileMapImg.width / pxTileSize; // nombre max de tuile par ligne en fonction de la largeur en pixel de l'image tileMap
    spriteWidth = pxTileSize;
    SpriteHeight = pxTileSize * 2;
    /*  on va remplir d'image miniature "tuile" : lHardBlockTilesImages
     la tileMap à systematiquement une largeur en pixel égale à un multiple de la taille d'une tuile   */
    int yTileMapBomberManSpriteDecal = pxTileSize*9; // les sprites de bomberman se trouve à une position plus basse dans l'image. (9 tuiles plus bas)
    for (int incr1 = 0; incr1 < totalSprite; incr1++) {
      int xSource = (incr1 % TilePerWidth) * spriteWidth; // position x et y dans l'image source tileMap
      int ySource = (floor(incr1 / TilePerWidth) * SpriteHeight) + yTileMapBomberManSpriteDecal;
      PImage i = createImage(spriteWidth, SpriteHeight, ARGB); // on crée une image a la volée avec un canal alpha
      i.copy(tileMapImg, xSource, ySource, spriteWidth, SpriteHeight, 0, 0, spriteWidth, SpriteHeight); // on copie le contenu
      lPlayerImages.add(i); // on stocke chaque miniature...
    }


    // on construit les animations
    for (Action a : Action.values()) {
      
      lAnimation.put(a, new SpriteAnimation(a));
    }
    
    blockPosition = SpawnPosition;
    
    
    rect.x = (SpawnPosition % map.blocksWidth) * pxTileSize;
    rect.y = floor(SpawnPosition / map.blocksWidth) * pxTileSize;
    rect.h = pxTileSize;
    rect.w = pxTileSize;
    walkSpeed = 1;
    bControl = true;
    spriteToRender = new Sprite(1,rect.x,rect.y,0); // default..
    //    xPos = (SpawnPosition % 30 ) * pxTileSize;
    //    yPos = floor(SpawnPosition / 30) * pxTileSize;
  }

  public void render() {
    
    
    image(lPlayerImages.get(spriteToRender.TileID), spriteToRender.xDecal,spriteToRender.yDecal);
  }

  public void setActiveControl(boolean b) {
    bControl =b;
  }

  public void updateAction() {
    Action b;
    if (bControl) { // si le joueur a l'accès...
      if (gCtrl.left) {
        b =  tryLeftStep();
      } else if (gCtrl.right) {
        b = tryRightStep();
      } else if (gCtrl.up) {
        b = tryUpStep();
      } else if (gCtrl.down) {
        b = tryDownStep();
      } else if (gCtrl.a) {
        b = Action.DIE;
      } else if (gCtrl.b) {
        b = Action.VICTORY;
      } else {
        b = Action.VOID;
      }
    } else {
      b = Action.VOID;
    }
    
    /* mise a jour de l'affichage du personnage
     - en fonction de l'action en cours
     - en fonction du sprite de l'animation en cours
     - en fonction du décalage x et Y
     */
    if (b == Action.VOID) {
      switch (previousAction) {
      case LOOK_LEFT_WALK:
        b = Action.LOOK_LEFT_WAIT;
        break;
      case LOOK_RIGHT_WALK:
        b = Action.LOOK_RIGHT_WAIT;
        break;
      case LOOK_UP_WALK:
        b = Action.LOOK_UP_WAIT;
        break;
      case LOOK_DOWN_WALK:
        b = Action.LOOK_FRONT_WAIT;
        break;
      default:
        b = previousAction;
        break;
      }
    }



    if (b != previousAction) { // reset du compteur de frame s'il y a reset.
      previousAction = b;
      frameCounter = 0;
    }


    SpriteAnimation sa = lAnimation.get(b);
    Sprite s;
    int index = Arrays.binarySearch(sa.framesPos, frameCounter);
    if (index >= 0) {
      s = sa.sprites.get(index);
    } else { // negative value is the conditional new entry index 
      s = sa.sprites.get(abs(index)-1);
    }
    spriteToRender = new Sprite(s.TileID, s.xDecal + rect.x, s.yDecal + rect.y - 16,0);
    //image(lPlayerImages.get(s.TileID), s.xDecal+x, s.yDecal+y -16);
    frameCounter++;
    if (frameCounter> sa.MaxFrame) {
      frameCounter = sa.FrameLoop;
    }
  }


  private Action tryRightStep() {
    if ( map.checkHardBlockCollision(blockPosition+1, rect)) {
      rect.x +=walkSpeed; 
      int yDiff = map.getYdifference(blockPosition+1, rect.y);
      if (yDiff < 0) {
        if (map.IsStopPlayerBlock(blockPosition+1 + map.blocksWidth)||map.IsStopPlayerBlock(blockPosition + map.blocksWidth)) {
          if (abs(yDiff)< walkSpeed) {
            rect.y -= abs(yDiff);
          } else {
            rect.y -= walkSpeed;
          }
        }
      } else if (yDiff>0) {
        if (map.IsStopPlayerBlock(blockPosition+1 - map.blocksWidth)||map.IsStopPlayerBlock(blockPosition - map.blocksWidth)) {
          if (abs(yDiff)< walkSpeed) {
            rect.y += abs(yDiff);
          } else {
            rect.y += walkSpeed;
          }
        }
      }
      blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
      return Action.LOOK_RIGHT_WALK;
    } else {
      int yDiff = map.getYdifference(blockPosition+1, rect.y);
      if (yDiff < 0) { 
        
        if (!map.IsStopPlayerBlock(blockPosition + map.blocksWidth) && !map.IsStopPlayerBlock(blockPosition + map.blocksWidth+1)) {
          rect.y +=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_DOWN_WALK;
        }
      } else if (yDiff > 0) {
        
        if (!map.IsStopPlayerBlock(blockPosition - map.blocksWidth) && !map.IsStopPlayerBlock(blockPosition - map.blocksWidth+1)) {
          rect.y -=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_UP_WALK;
        }
      }
    }
    return Action.LOOK_RIGHT_WALK;
  }

  private Action tryLeftStep() {
    if ( map.checkHardBlockCollision(blockPosition-1, rect)) {
      rect.x -=walkSpeed; // on avance
      int yDiff = map.getYdifference(blockPosition-1, rect.y);
      if (yDiff < 0) {
        if (map.IsStopPlayerBlock(blockPosition-1 + map.blocksWidth)||map.IsStopPlayerBlock(blockPosition + map.blocksWidth)) {
          if (abs(yDiff)< walkSpeed) {
            rect.y -= abs(yDiff); // +
          } else {
            rect.y -= walkSpeed;
          }
        }
      } else if (yDiff>0) {
        if (map.IsStopPlayerBlock(blockPosition -1 - map.blocksWidth)||map.IsStopPlayerBlock(blockPosition  - map.blocksWidth)) {
          if (abs(yDiff)< walkSpeed) {
            rect.y += abs(yDiff);
          } else {
            rect.y += walkSpeed;
          }
        }
      }
      blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
      return Action.LOOK_LEFT_WALK;
    } else {
      int yDiff = map.getYdifference(blockPosition-1, rect.y);
      if (yDiff < 0) { // plus bas
        
        if (!map.IsStopPlayerBlock(blockPosition + map.blocksWidth) && !map.IsStopPlayerBlock(blockPosition + map.blocksWidth-1)) {
          rect.y +=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_DOWN_WALK;
        }
      } else if (yDiff > 0) {
        
        if (!map.IsStopPlayerBlock(blockPosition - map.blocksWidth) && !map.IsStopPlayerBlock(blockPosition - map.blocksWidth-1)) {
          rect.y -=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_UP_WALK;
        }
      }
    }
    return Action.LOOK_LEFT_WALK;
  }

  private Action tryUpStep() {
    if ( map.checkHardBlockCollision(blockPosition- map.blocksWidth, rect)) {
      rect.y -=walkSpeed; // on avance
      int xDiff = map.getXdifference(blockPosition- map.blocksWidth, rect.x);
      if (xDiff > 0) {
        if (map.IsStopPlayerBlock(blockPosition - 1 - map.blocksWidth) || map.IsStopPlayerBlock(blockPosition -1 )) {
          if (abs(xDiff)< walkSpeed) {
            rect.x += abs(xDiff); // +
          } else {
            rect.x += walkSpeed;
          }
        }
      } else if (xDiff<0) {
        if (map.IsStopPlayerBlock(blockPosition + 1 - map.blocksWidth)||map.IsStopPlayerBlock(blockPosition +1)) {
          if (abs(xDiff)< walkSpeed) {
            rect.x -= abs(xDiff);
          } else {
            rect.x -= walkSpeed;
          }
        }
      }
      blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
      return Action.LOOK_UP_WALK;
    } else {
      int xDiff = map.getXdifference(blockPosition- map.blocksWidth, rect.x);
      if (xDiff > 0) { 
        if (!map.IsStopPlayerBlock(blockPosition - 1) && !map.IsStopPlayerBlock(blockPosition - map.blocksWidth-1)) {
          rect.x -=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_LEFT_WALK;
        }
      } else if (xDiff < 0) {
        
        if (!map.IsStopPlayerBlock(blockPosition +1 ) && !map.IsStopPlayerBlock(blockPosition - map.blocksWidth+1)) {
          rect.x +=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_RIGHT_WALK;
        }
      }
    }
    return Action.LOOK_UP_WALK;
  }

  private Action tryDownStep() {
    if (map.checkHardBlockCollision(blockPosition +  map.blocksWidth, rect)) {
      rect.y +=walkSpeed; // on avance
      int xDiff = map.getXdifference(blockPosition+ map.blocksWidth, rect.x);
      if (xDiff > 0) {
        if (map.IsStopPlayerBlock(blockPosition - 1 + map.blocksWidth) || map.IsStopPlayerBlock(blockPosition -1 )) {
          if (abs(xDiff)< walkSpeed) {
            rect.x += abs(xDiff); // +
          } else {
            rect.x += walkSpeed;
          }
        }
      } else if (xDiff<0) {
        if (map.IsStopPlayerBlock(blockPosition + 1 + map.blocksWidth)||map.IsStopPlayerBlock(blockPosition +1)) {
          if (abs(xDiff)< walkSpeed) {
            rect.x -= abs(xDiff);
          } else {
            rect.x -= walkSpeed;
          }
        }
      }
      blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
      return Action.LOOK_DOWN_WALK;
    } else {
      int xDiff = map.getXdifference(blockPosition+ map.blocksWidth, rect.x);
      if (xDiff > 0) { 
        if (!map.IsStopPlayerBlock(blockPosition - 1) && !map.IsStopPlayerBlock(blockPosition + map.blocksWidth-1)) {
          rect.x -=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_LEFT_WALK;
        }
      } else if (xDiff < 0) {
        
        if (!map.IsStopPlayerBlock(blockPosition +1 ) && !map.IsStopPlayerBlock(blockPosition + map.blocksWidth+1)) {
          rect.x +=1;
          blockPosition = map.getBlockPositionFromCoordinate(rect.x, rect.y);
          return Action.LOOK_RIGHT_WALK;
        }
      }
    }
    return Action.LOOK_DOWN_WALK;
  }




  class SpriteAnimation {
    
    int FrameLoop = 0;
    int MaxFrame = 0;
    int[] framesPos;
    ArrayList<Sprite> sprites = new ArrayList<Sprite>();

    public SpriteAnimation(Action a) {
      switch (a) {
      case LOOK_FRONT_WAIT:
        addSprite(7);
        break;
      case LOOK_LEFT_WAIT:
        addSprite(10);
        break;
      case LOOK_RIGHT_WAIT:
        addSprite(4);
        break;
      case LOOK_UP_WAIT:
        addSprite(1);
        break;
      case LOOK_DOWN_WALK:
        addSprite(8, 10);
        addSprite(7, 10);
        addSprite(9, 10);
        addSprite(7, 10);
        break;
      case LOOK_LEFT_WALK:
        addSprite(11, 10);
        addSprite(10, 10);
        addSprite(12, -1, 0, 10);
        addSprite(10, 10);
        break;
      case LOOK_RIGHT_WALK:
        addSprite(5, 1, 0, 10);
        addSprite(4, 10);
        addSprite(6, 10); // decalage sur X
        addSprite(4, 10);
        break;
      case LOOK_UP_WALK:
        addSprite(2, 10);
        addSprite(1, 10);
        addSprite(3, 10);
        addSprite(1, 10);
        break;
      case DIE:
        //addSprite(7, 120);
        //addSprite(37, 30); 
        addSprite(37, 1);   // 4 spins !
        addSprite(39, 1);
        addSprite(14, 1);
        addSprite(38, 1);
        addSprite(37, 1);   // 4 spins !
        addSprite(39, 1);
        addSprite(14, 1);
        addSprite(38, 1);
        addSprite(37, 1);
        addSprite(39, 1);  
        addSprite(14, 2);
        addSprite(38, 2); 
        addSprite(37, 2);
        addSprite(39, 2);  
        addSprite(14, 2);
        addSprite(38, 2);       
        addSprite(37, 2);
        addSprite(39, 2);   
        addSprite(14, 2);
        addSprite(38, 2);      
        addSprite(37, 3);
        addSprite(39, 5);
        addSprite(14, 8);   
        addSprite(38, 10);  
        addSprite(37, 15); 
        addSprite(40, 15);
        addSprite(41, 15);
        addSprite(42, 5);
        addSprite(43, 5);
        addSprite(44, 5);
        addSprite(43, 5);
        addSprite(45, 5);
        addSprite(43, 5);
        addSprite(44, 5);
        addSprite(43, 5);
        addSprite(45, 5);
        addSprite(43, 5);
        addSprite(44, 5);
        addSprite(43, 5);
        addSprite(45, 5);
        addSprite(43, 5);
        addSprite(42, 5);
        addSprite(43, 5);
        setFrameLoop(40); // loop depuis le sprite 40
        break;
      case VICTORY:
        addSprite(134, 60);
        addSprite(132, 10);
        addSprite(133, 10);
        addSprite(132, 10);
        addSprite(133, 10);
        addSprite(132, 10);
        addSprite(133, 60);
        setFrameLoop(6); // loop sur le dernier sprite
        break;
        // les animations suivantes ne sont pas détaillées pour le moment....
      case GROUND_APPEAR:
      case GROUND_DISAPPEAR:
      case TINY_DISAPPEAR:
      case LOOK_FRONT_CARRY_WAIT:
      case LOOK_LEFT_CARRY_WAIT:
      case LOOK_RIGHT_CARRY_WAIT:
      case LOOK_UP_CARRY_WAIT:
      case LOOK_FRONT_CARRY_WALK:
      case LOOK_LEFT_CARRY_WALK:
      case LOOK_RIGHT_CARRY_WALK:
      case LOOK_UP_CARRY_WALK:
      case LOOK_FRONT_THROW:
      case LOOK_LEFT_THROW:
      case LOOK_RIGHT_THROW:
      case LOOK_UP_THROW:
      default:
        addSprite(110);
        break;
      }
      if (MaxFrame == 0) {
        rebuildFramesTiming();
      }
    }

    private void setFrameLoop(int nSprite) { // défaut : boucle de la dernière vers la première
      if (nSprite == 0) {
        FrameLoop = 0;
      } else {
        if (MaxFrame == 0) {
          rebuildFramesTiming();
        }
        FrameLoop = framesPos[nSprite];
      }
    }

    private void rebuildFramesTiming() {
      framesPos = new int[sprites.size()];
      Sprite s;
      for (int incr = 0; incr < sprites.size(); incr++) {
        s = sprites.get(incr);
        framesPos[incr] = s.duration + MaxFrame;
        MaxFrame += s.duration;
      }
    }



    private void addSprite(int TileID, int xDecal, int yDecal, int duration) {
      sprites.add(new Sprite(TileID-1, xDecal, yDecal, duration));
    }
    private void addSprite(int TileID) {
      addSprite(TileID, 0, 0, 60);
    }
    private void addSprite(int TileID, int duration) {
      addSprite(TileID, 0, 0, duration);
    }
  }

  class Sprite {
    int TileID;
    int xDecal;
    int yDecal;
    int duration;
    

    public Sprite(int TileID, int xDecal, int yDecal, int duration) {
      this.TileID = TileID;
      this.xDecal = xDecal;
      this.yDecal = yDecal;
      this.duration = duration;
    }
  }
}  