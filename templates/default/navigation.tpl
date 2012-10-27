<template name="navigation" hidden="true">

	<template name="toolbar" assign="NAV.Toolbar">
		{NAV.Lnk_First}
		{NAV.Lnk_Previous}
		{NAV.Lnk_Next}
		{NAV.Lnk_Last}
	</template>

	<template name="menu">
		<ul>
		<template name="menu_option">
			<li><a href="{NAV.Target}" title="{NAV.Title}"><span>{NAV.sTitle}</span></a></li>
		</template>
		</ul>
	</template>

	<template name="menu_option_hilight">
		<li id="current"><a href="{NAV.Target}" title="{NAV.Title}"><span>{NAV.sTitle}</span></a></li>
	</template>

</template>