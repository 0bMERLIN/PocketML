import lib.tea;

let view _ = ColorPicker "colpicker" @(width/2,200) @(0,300);

let tick e s = forceUpdate s
;

app () tick view
