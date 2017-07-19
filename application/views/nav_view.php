    <nav id="main-nav">
        <div class="navigation" ng-controller="HomeController">      
            <ul class="nav nav-stacked">
                <li class="">
                    <a class="dropdown-collapse in" href="#">
                        <i class="icon-sitemap"></i>
                        <span>Network</span>
                        <i class="icon-angle-down angle-down"></i>
                    </a>                                        
                    <ul class="in nav nav-stacked">
                        <?php foreach($regions as $r): ?>
                        <li>
                            <a class="dropdown-collapse in" href="#">
                                <i class="icon-caret-right"></i>
                                <span><?php echo $r->name; ?></span>
                                <i class="icon-angle-down angle-down"></i>
                            </a>
                            <ul class="in nav nav-stacked">
                                <?php foreach($r->children as $a): ?>
                                <li>
                                    <a class="dropdown-collapse">
                                        <i class="icon-caret-right"></i>
                                        <span><?php echo $a->name; ?></span>
                                        <i class="icon-angle-down angle-down"></i>
                                    </a>
                                    <ul class="in nav nav-stacked">
                                        <?php foreach($a->children as $s): ?>
                                        <li>
                                            <a ng-click="open('<?php echo $s->id; ?>')">
                                                <i class="icon-map-marker"></i>
                                                <span><?php echo $s->name; ?></span>
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