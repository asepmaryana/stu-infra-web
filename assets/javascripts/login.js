function show_dlg_msg(title, msg)
{
    $('#dlg_title').html(title);
    $('#dlg_body').html(msg);
    $('#frmDlg').modal('show');
}

function login()
{
    user = $('#username').val().trim();
    pass = $('#password').val().trim();
    
    if(user == '') {
        show_dlg_msg('Exception', 'Username is required !');
        setTimeout(function(){ $('#frmDlg').modal('toggle'); }, 2000);
    }
    else if(pass == '') {
        show_dlg_msg('Exception', 'Password is required !');
        setTimeout(function(){ $('#frmDlg').modal('toggle'); }, 2000);
    }
    else {
        $.post(base_url+'api/auth/login', $("#form_login").serialize(),function(result){
            if (result.success){
                show_dlg_msg('Success', result.msg);
                setTimeout(function(){ 
                    $('#frmDlg').modal('toggle');
                    window.location.href = base_url + 'home'; 
                }, 2000);
            } else {
                show_dlg_msg('Exception', result.msg);
                setTimeout(function(){ $('#frmDlg').modal('toggle'); }, 2000);
            }
        },'json');
    }
}

$(document).ready(function(){
    $('#username').keypress(function(e){ if(e.which == 13) login(); });
    $('#password').keypress(function(e){ if(e.which == 13) login(); });
});