    <nav id="main-nav">
        <div class="navigation" ng-controller="HomeController">      
            <ul class="nav nav-stacked">
                <li class="">
                    <a class="dropdown-collapse in" href="#">
                        <span>NETWORK</span>
                        <i class="icon-angle-down angle-down"></i>
                    </a>                                        
                    <ul class="in nav nav-stacked">
                        <?php foreach($regions as $r): ?>
                        <li>
                            <a class="dropdown-collapse in" href="#">
                                <i class="icon-globe"></i>
                                <span><?php echo $r->name; ?></span>
                                <i class="<?php if($r->alarm) echo 'icon-bell fa-blink'; ?>" id="r<?php echo $r->id; ?>"></i>
                                <i class="icon-angle-down angle-down"></i>
                            </a>
                            <ul class="in nav nav-stacked">
                                <?php foreach($r->children as $a): ?>
                                <li>
                                    <a class="dropdown-collapse">
                                        <i class="icon-sitemap"></i>
                                        <span><?php echo $a->name; ?></span>
                                        <i class="<?php if($a->alarm) echo 'icon-bell fa-blink'; ?>" id="a<?php echo $a->id; ?>"></i>
                                        <i class="icon-angle-down angle-down"></i>
                                    </a>
                                    <ul class="in nav nav-stacked">
                                        <?php foreach($a->children as $s): ?>
                                        <li>
                                            <a ng-click="open('<?php echo $s->id; ?>')">
                                                <i class="icon-map-marker"></i>
                                                <span><?php echo $s->name; ?></span>
                                                <i class="<?php if($s->alarm) echo 'icon-bell fa-blink'; ?>" id="s<?php echo $s->id; ?>"></i>
                                            </a>
                                        </li>
                                        <?php endforeach; ?>  
                                    </ul>                                                                                                        
                                </li>
                                <?php endforeach; ?>                            
                            </ul>                                                        
                        </li>
                        <?php endforeach; ?>
                    </ul>
                </li>
            </ul>
        </div>   
    </nav>