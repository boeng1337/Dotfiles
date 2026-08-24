import QtQuick

Canvas {
	id: corner
	property string side: "left"
	property color fill: "red"
	property real r: 12
	width: r 
	height: r
	onPaint: {
		var ctx = getContext("2d")
		ctx.reset()
		ctx.fillStyle = fill	
		if (side === "left" ) {
			ctx.beginPath()
			ctx.moveTo(0, 0)
			ctx.lineTo(r, 0)
			ctx.lineTo(r, r)
			ctx.arc(0, r, r, 0, -Math.PI/ 2, true)
			ctx.closePath()
			ctx.fill()
		}
		else {
			ctx.beginPath()
			ctx.moveTo(r, 0)
			ctx.lineTo(0, 0)
			ctx.lineTo(0, r)
			ctx.arc(r, r, r, Math.PI, -Math.PI/ 2, false)
			ctx.closePath()
			ctx.fill()

		}
	}
}

