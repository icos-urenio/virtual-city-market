<template parent="main" assign="PAGE.Body">
	
	<php>
		if ($_GET['bare']) {
			$this->parseTemplate('TERMS', 'bare');
			$this->printTemplate('TERMS');
			exit;
		}
		else {
			$this->disableTemplate('bare');
		}
	</php>
	
	<template name="normal">
		<div class="container">
			<div class="row">
				<div class="span12">
					<header id="archive-header" style="padding-left: 40px;">
						<h2>{PAGE.Title}</h2>
					</header>
				</div>
			</div>
		</div>
		
		<div class="container">
			<div class="row">
				<div class="span10 offset1">
					{PAGE.Text}
				</div>
			</div>
		</div>
	</template>
	
	<template name="bare">
		{PAGE.Text}
	</template>

</template>