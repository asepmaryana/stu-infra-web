<header ng-controller="HeaderController">
      <nav class="navbar navbar-default">
        <a class="navbar-brand" href="<?php echo base_url(); ?>home">
          <img class="logo" alt="" src="<?php echo base_url(); ?>assets/images/logo.png" />
        </a>
        <a class="toggle-nav btn pull-left" href="#">
          <i class="icon-reorder"></i>
        </a>
        
        <ul class="nav">
          <li class="dropdown light only-icon">
            <a class="dropdown-toggle" data-toggle="dropdown">
              <i class="icon-cog"></i>
            </a>
            <ul class="dropdown-menu color-settings">
                <!--
              <li class="color-settings-body-color">
                <div class="color-title">Change body color</div>
                <a data-change-to="<?php echo base_url(); ?>assets/stylesheets/light-theme.css" href="#">
                  Light
                  <small>(default)</small>
                </a>
                <a data-change-to="<?php echo base_url(); ?>assets/stylesheets/dark-theme.css" href="#">
                  Dark
                </a>
                <a data-change-to="<?php echo base_url(); ?>assets/stylesheets/dark-blue-theme.css" href="#">
                  Dark blue
                </a>
              </li>
              <li class="divider"></li>
              -->
              <li class="color-settings-contrast-color">
                <div class="color-title">Change contrast color</div>
                            <a data-change-to="contrast-red" href="#"><i class="icon-cog text-red"></i>
                Red
                <small>(default)</small>
                </a>
    
                            <a data-change-to="contrast-blue" href="#"><i class="icon-cog text-blue"></i>
                Blue
                </a>
    
                            <a data-change-to="contrast-orange" href="#"><i class="icon-cog text-orange"></i>
                Orange
                </a>
    
                            <a data-change-to="contrast-purple" href="#"><i class="icon-cog text-purple"></i>
                Purple
                </a>
    
                            <a data-change-to="contrast-green" href="#"><i class="icon-cog text-green"></i>
                Green
                </a>
    
                            <a data-change-to="contrast-muted" href="#"><i class="icon-cog text-muted"></i>
                Muted
                </a>
    
                            <a data-change-to="contrast-fb" href="#"><i class="icon-cog text-fb"></i>
                Facebook
                </a>
    
                            <a data-change-to="contrast-dark" href="#"><i class="icon-cog text-dark"></i>
                Dark
                </a>
    
                            <a data-change-to="contrast-pink" href="#"><i class="icon-cog text-pink"></i>
                Pink
                </a>
    
                            <a data-change-to="contrast-grass-green" href="#"><i class="icon-cog text-grass-green"></i>
                Grass green
                </a>
    
                            <a data-change-to="contrast-sea-blue" href="#"><i class="icon-cog text-sea-blue"></i>
                Sea blue
                </a>
    
                            <a data-change-to="contrast-banana" href="#"><i class="icon-cog text-banana"></i>
                Banana
                </a>
    
                            <a data-change-to="contrast-dark-orange" href="#"><i class="icon-cog text-dark-orange"></i>
                Dark orange
                </a>
    
                            <a data-change-to="contrast-brown" href="#"><i class="icon-cog text-brown"></i>
                Brown
                </a>
    
              </li>
            </ul>
          </li>
          <!--
          <li class="dropdown medium only-icon widget">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
              <i class="icon-rss"></i>
              <div class="label">5</div>
            </a>
            <ul class="dropdown-menu">
              <li>
                <a href="#">
                  <div class="widget-body">
                    <div class="pull-left icon">
                      <i class="icon-user text-success"></i>
                    </div>
                    <div class="pull-left text">
                      John Doe signed up
                      <small class="text-muted">just now</small>
                    </div>
                  </div>
                </a>
              </li>
              <li class="divider"></li>
              <li>
                <a href="#">
                  <div class="widget-body">
                    <div class="pull-left icon">
                      <i class="icon-inbox text-error"></i>
                    </div>
                    <div class="pull-left text">
                      New Order #002
                      <small class="text-muted">3 minutes ago</small>
                    </div>
                  </div>
                </a>
              </li>
              <li class="divider"></li>
              <li>
                <a href="#">
                  <div class="widget-body">
                    <div class="pull-left icon">
                      <i class="icon-comment text-warning"></i>
                    </div>
                    <div class="pull-left text">
                      America Leannon commented Flatty with veeery long text.
                      <small class="text-muted">1 hour ago</small>
                    </div>
                  </div>
                </a>
              </li>
              <li class="divider"></li>
              <li>
                <a href="#">
                  <div class="widget-body">
                    <div class="pull-left icon">
                      <i class="icon-user text-success"></i>
                    </div>
                    <div class="pull-left text">
                      Jane Doe signed up
                      <small class="text-muted">last week</small>
                    </div>
                  </div>
                </a>
              </li>
              <li class="divider"></li>
              <li>
                <a href="#">
                  <div class="widget-body">
                    <div class="pull-left icon">
                      <i class="icon-inbox text-error"></i>
                    </div>
                    <div class="pull-left text">
                      New Order #001
                      <small class="text-muted">1 year ago</small>
                    </div>
                  </div>
                </a>
              </li>
              <li class="widget-footer">
                <a href="#">All notifications</a>
              </li>
            </ul>
          </li>
          -->
          <li class="dropdown dark user-menu">
            <a class="dropdown-toggle" data-toggle="dropdown">
              <img width="23" height="23" alt="" src="<?php echo base_url(); ?>assets/images/avatar.jpg" />
              <span class="user-name">{{userinfo.name}}</span>
              <b class="caret"></b>
            </a>
            <ul class="dropdown-menu">
              <li>
                <a href="#/profile">
                  <i class="icon-user"></i>
                  Profile
                </a>
              </li>
              <li>
                <a href="#/setting">
                  <i class="icon-cog"></i>
                  Settings
                </a>
              </li>
              <li class="divider"></li>
              <li>
                <a href="#" ng-click="logout()">
                  <i class="icon-signout"></i>
                  Sign out
                </a>
              </li>
            </ul>
          </li>
        </ul>
        
        <form class="navbar-form navbar-right hidden-xs">
          <button class="btn btn-link icon-search" name="button" type="button"></button>
          <div class="form-group">
            <input type="text" class="form-control" ng-click="gosite()" placeholder="Search..." autocomplete="off" id="typeahead" />
          </div>
        </form>
        
        <ul class="nav">
            <li class="dropdown">
                <a class="dropdown-toggle" data-toggle="dropdown">
                    <i class="icon-dashboard"></i>
                    Dashboard
                    <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                    <li>
                        <a href="#/dashboard/map" ng-click="reloadMap()">
                            <i class="icon-map-marker"></i>
                            Map
                        </a>
                    </li>
                    <li>
                        <a href="#/dashboard/summary">
                            <i class="icon-bar-chart"></i>
                            Summaries
                        </a>
                    </li>
                </ul>
            </li>
            <li>
                <a href="#/surveillance">
                    <i class="icon-eye-open"></i>
                    Surveillance
                </a>
            </li>
            <li class="dropdown">
                <a class="dropdown-toggle" data-toggle="dropdown">
                    <i class="icon-archive"></i>
                    Reporting
                    <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                    <li>
                        <a href="#/alarmlog">
                            <i class="icon-bolt"></i>
                            Alarm Log
                        </a>
                    </li>
                    <li>
                        <a href="#/datalog">
                            <i class="icon-table"></i>
                            Data Log
                        </a>
                    </li>
                </ul>
            </li>
            <li class="dropdown" ng-if="userinfo.role_id != 3">
                <a class="dropdown-toggle" data-toggle="dropdown">
                    <i class="icon-gears"></i>
                    Management
                    <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                    <li>
                        <a href="#/admin/customer">
                            <i class="icon-user-md"></i>
                            Customer
                        </a>
                    </li>
                    <li>
                        <a href="#/admin/severity">
                            <i class="icon-bolt"></i>
                            Alarm Sverity
                        </a>
                    </li>
                    <li>
                        <a href="#/admin/alarm">
                            <i class="icon-table"></i>
                            Alarm List
                        </a>
                    </li>
                    <li>
                        <a href="#/admin/region">
                            <i class="icon-globe"></i>
                            Region
                        </a>
                    </li>
                    <li>
                        <a href="#/admin/area">
                            <i class="icon-sitemap"></i>
                            Area
                        </a>
                    </li>
                    <li>
                        <a href="#/admin/site">
                            <i class="icon-map-marker"></i>
                            Site
                        </a>
                    </li>                    
                    <li>
                        <a href="#/admin/user">
                            <i class="icon-user"></i>
                            Account
                        </a>
                    </li>
                    <li>
                        <a href="#/admin/operator">
                            <i class="icon-user"></i>
                            Operator
                        </a>
                    </li>
                </ul>
            </li>
			
        </ul>
        
      </nav>
    </header>