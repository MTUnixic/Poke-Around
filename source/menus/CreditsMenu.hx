package menus;

import BackgrndState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxContainer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import util.MenuUtil;
import util.MouseUtil;

@:structInit private class Credited extends FlxContainer
{
    public var iSprite = new FlxSprite();
    public var description = new FlxText();
    public var header = new FlxTypedContainer<FlxText>();

    var iFrame = 0;
    var descX:Float;
    var isDescOpened = false;
    var maskX = 180;

    var textColor:FlxColor;
    var outlineColor:FlxColor;
    var nameText:FlxText;

    public function new(iconFrame:Int, ?maskX = 180) 
    {
        super();

        this.iFrame = iconFrame;
        this.maskX = maskX;

        iSprite.loadGraphic('assets/images/pokuhicons.png', true, 64, 64);
        iSprite.setGraphicSize(iSprite.width*2, iSprite.height*2);
        iSprite.animation.add('icon', [iconFrame]);
        iSprite.animation.play('icon');

        updateMask(description, maskX);

        add(description);
        add(iSprite);
        add(header);
    }

    inline function updateMask(text:FlxText, ?maskX:Float)
    {
        maskX ??= FlxG.width / 2; // position of mask boundary across the screen
        final clipX = Math.max(0, maskX-text.x); // ignores clipX if it's in the negatives (way past the cliprect)

        text.clipRect = new FlxRect(clipX, 0, text.width-clipX, text.height); // text.width-clipX is how many pixels aren't masked / are visible
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.mouse.overlaps(iSprite)) {
            iSprite.scale.set(iSprite.scale.x+0.1, iSprite.scale.y+0.1);
            if (iSprite.scale.x >= 2.25) iSprite.scale.setXY(2.25);
        } else {
            iSprite.scale.set(iSprite.scale.x-0.1, iSprite.scale.y-0.1);
            if (iSprite.scale.x <= 2) iSprite.scale.setXY(2);
        }

        if (MouseUtil.justClicked(iSprite) && !isDescOpened) {
            isDescOpened = true;
            FlxTween.tween(description, {x: descX}, 3, {
                ease: FlxEase.circOut,
                onUpdate: function(_) updateMask(description, maskX)
            });
        }
    }

    public inline function posIcon(x:Float, y:Float)
    {
        iSprite.setPosition(x, y);
    }

    public inline function makeDescription(?desc:String, ?color:FlxColor)
    {
        descX = iSprite.x + 125;
        description.y = iSprite.y + 52 - 8;
        description.size = 24;
        color ??= 0xFF6D758D;
        description.color = color;
        if (desc == null) {
            desc = 'Heh, what a predictable creature.. LAST, JARONA!';
            description.alpha = 0.5;
        }
        description.text = '"' + desc + '"';
        description.x = -description.width;
    }

    public inline function makeHeaderName(title:String, textColor:Int, outlineColor:Int)
    {
        nameText = new FlxText(iSprite.x + 125, iSprite.y - 8);
        nameText.text = title;
        nameText.size = 32;
        nameText.color = textColor;
        nameText.borderStyle = OUTLINE;
        nameText.borderSize = 3;
        nameText.borderColor = outlineColor;

        this.textColor = textColor;
        this.outlineColor = outlineColor;

        header.add(nameText);
    }

    public inline function addHeaderQualities(qualities:Array<String>)
    {
        if (textColor == null || outlineColor == null || nameText == null)
            throw '[MISSING] - you must use makeHeaderName(name, textcolor, outlinecolor) first before adding qualities to the header!!';

        final dash = new FlxText(nameText.x + nameText.width + 8, iSprite.y - 8);
        dash.color = outlineColor;
        dash.text = '-';
        dash.size = 32;
        header.add(dash);

        var lastText = dash;

        for (quality in qualities) {
            final h = new FlxText(lastText.x + lastText.width + 8, iSprite.y - 8);
            h.size = 32;
            h.text = quality;
            header.add(h);
            lastText = h;
        }
    }
}

class CreditsMenu extends BackgrndState
{
    var buttonGroup:FlxTypedGroup<FlxText>;
	var menu:MenuUtil;

    var mtunixic = new Credited(0);
    var davvex87 = new Credited(1);
    var chungus = new Credited(2);
    var codeanomaly08 = new Credited(3);

    override function create()
    {
        super.create();

        remove(glow, true);
		remove(frame, true);
		remove(pokerTable, true);

        mtunixic.posIcon(180, 120);
        mtunixic.makeHeaderName('MT Unixic', 0xFFFFFC40, 0xFFDF3E23);
        mtunixic.makeDescription('Though it was tiring, I loved working on this,\nand I am glad to be a part of my first ever team!\nIt would not have been possible at all without them,\nand I thank everyone so much for that :]');
        mtunixic.addHeaderQualities(['Director', 'Coder', 'Artist', 'Animator']);

        davvex87.posIcon(180, 320);
        davvex87.makeHeaderName('Davvex87', 0xFF20D6C7, 0xFF143464);
        davvex87.makeDescription();
        davvex87.addHeaderQualities(['Co-Director', 'Coder']);

        chungus.posIcon(180, 440);
        chungus.makeHeaderName('Besomething (be n)', 0xFFDF3E23, 0xFF422433);
        chungus.makeDescription();
        chungus.addHeaderQualities(['Coder']);

        codeanomaly08.posIcon(180, 560);
        codeanomaly08.makeHeaderName('Mike', 0xFF9CCB43, 0xFF24523B);
        codeanomaly08.makeDescription();
        codeanomaly08.addHeaderQualities(['Coder']);

        add(mtunixic);
        add(davvex87);
        add(chungus);
        add(codeanomaly08);

        menu = new MenuUtil(['Go Back']);
	
		buttonGroup = new FlxTypedGroup<FlxText>();
		menu.makeButtonGroup(buttonGroup);

        for (buttonText in buttonGroup) {
            buttonText.y = FlxG.height - buttonText.height - 8;
        }
		menu.addConfirmOption('Go Back', () -> FlxG.switchState(() -> new MainMenu()));
		add(buttonGroup);

        var music = FlxG.sound.create("assets/music/buckshot-mt-piano.ogg");
        music.play(true);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        menu.updateLoop();
        MouseUtil.mouseCamera();
    }
}