package menus;

import BackgrndState;
import util.MouseUtil;

class GuideMenu extends BackgrndState
{
    override function create()
    {
        super.create();

        remove(glow, true);
		remove(frame, true);
		remove(pokerTable, true);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        MouseUtil.mouseCamera();
    }
}