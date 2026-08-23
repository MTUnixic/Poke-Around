package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;

class BackgrndState extends FlxTransitionableState
{
    public var glow:FlxSprite;

    var frame:FlxSprite;
	var pokerTable:FlxSprite;

    var diam:FlxBackdrop;
    
    public var squa:FlxBackdrop;
    
    override function create()
    {
        final bg = new FlxSprite();
        bg.loadGraphic('assets/images/coolbg/pokuhbg.png');
        bg.screenCenter();
        add(bg);

        diam = new FlxBackdrop('assets/images/coolbg/pokuhdiam.png');
        diam.scrollFactor.setXY(0.5);
        diam.velocity.setXY(50);
        diam.alpha = scratchGhost2Flixel(92);
        add(diam);

        squa = new FlxBackdrop('assets/images/coolbg/pokuhsqua.png');
        squa.scrollFactor.setXY(0.5);
        squa.velocity.setXY(-50);
        squa.alpha = scratchGhost2Flixel(95);
        add(squa);

        frame = new FlxSprite();
        frame.loadGraphic('assets/images/coolbg/pokuhbgframe.png');
        frame.scrollFactor.setXY(0.75);
        add(frame);

        pokerTable = new FlxSprite();
        pokerTable.loadGraphic('assets/images/pokuhtable.png');
		pokerTable.setGraphicSize(pokerTable.width * 2, pokerTable.height * 2);
		pokerTable.updateHitbox();
        pokerTable.screenCenter();
		pokerTable.y += 80;
        add(pokerTable); // put back insert 100 pokerTable if i fucked up sum -MT

        glow = new FlxSprite();
        glow.loadGraphic('assets/images/coolbg/pokuhbgglow.png');
        glow.alpha = scratchGhost2Flixel(40);
        add(glow);
        
        super.create();
    }

    /** too lazy to do the math **/
    inline function scratchGhost2Flixel(ghost:Int):Float
        return 1 - ( ghost / 100 );
}