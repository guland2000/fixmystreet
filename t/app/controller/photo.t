use FixMyStreet::TestMech;
use FixMyStreet::App;
use Web::Scraper;
use Path::Tiny;
use File::Temp 'tempdir';

# disable info logs for this test run
FixMyStreet::App->log->disable('info');
END { FixMyStreet::App->log->enable('info'); }

my $mech = FixMyStreet::TestMech->new;

my $sample_file = path(__FILE__)->parent->child("sample.jpg");
ok $sample_file->exists, "sample file $sample_file exists";

my $westminster = $mech->create_body_ok(2527, 'Liverpool City Council');

subtest "Check multiple upload worked" => sub {
    $mech->get_ok('/around');

    my $UPLOAD_DIR = tempdir( CLEANUP => 1 );

    # submit initial pc form
    FixMyStreet::override_config {
        ALLOWED_COBRANDS => [ { fixmystreet => '.' } ],
        MAPIT_URL => 'http://mapit.uk/',
        UPLOAD_DIR => $UPLOAD_DIR,
    }, sub {

        $mech->log_in_ok('test@example.com');


        # submit the main form
        # can't post_ok as we lose the Content_Type header
        # (TODO rewrite with HTTP::Request::Common and request_ok)
        $mech->get_ok('/report/new?lat=53.4031156&lon=-2.9840579');
        my ($csrf) = $mech->content =~ /name="token" value="([^"]*)"/;

        $mech->post( '/report/new',
            Content_Type => 'form-data',
            Content =>
            {
            submit_problem => 1,
            token => $csrf,
            title         => 'Test',
            lat => 53.4031156, lon => -2.9840579, # in Liverpool
            pc            => 'L1 4LN',
            detail        => 'Detail',
            photo1         => [ $sample_file, undef, Content_Type => 'application/octet-stream' ],
            photo2         => [ $sample_file, undef, Content_Type => 'application/octet-stream' ],
            photo3         => [ $sample_file, undef, Content_Type => 'application/octet-stream' ],
            name          => 'Bob Jones',
            may_show_name => '1',
            email         => 'test@example.com',
            phone         => '',
            category      => 'Street lighting',
            }
        );
        ok $mech->success, 'Made request with multiple photo upload';
        $mech->base_is('http://localhost/report/new');
        $mech->content_like(
            qr[(<img align="right" src="/photo/temp.74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg" alt="">\s*){3}],
            'Three uploaded pictures are all shown, safe');
        $mech->content_contains(
            'name="upload_fileid" value="74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg,74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg,74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg"',
            'Returned upload_fileid contains expected hash, 3 times');
        my $image_file = path($UPLOAD_DIR, '74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg');
        ok $image_file->exists, 'File uploaded to temp';

        $mech->submit_form_ok({ with_fields => { name => 'Bob Jones' } });
        ok $mech->success, 'Made request with multiple photo upload';
    };
};

subtest "Check photo uploading URL works" => sub {
    my $UPLOAD_DIR = tempdir( CLEANUP => 1 );

    # submit initial pc form
    FixMyStreet::override_config {
        UPLOAD_DIR => $UPLOAD_DIR,
    }, sub {
        $mech->post( '/photo/upload',
            Content_Type => 'form-data',
            Content => {
                photo1 => [ $sample_file, undef, Content_Type => 'application/octet-stream' ],
            },
        );
        ok $mech->success, 'Made request with multiple photo upload';
        is $mech->content, '{"id":"74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg"}';
        my $image_file = path($UPLOAD_DIR, '74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg');
        ok $image_file->exists, 'File uploaded to temp';
    };
};

subtest "Check photo URL endpoints work" => sub {
    my $p = FixMyStreet::DB->resultset("Problem")->first;

    $mech->get_ok('/photo/temp.74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg');
    my $image_file = FixMyStreet->path_to('web/photo/temp.74e3362283b6ef0c48686fb0e161da4043bbcc97.jpeg');
    ok -e $image_file, 'File uploaded to temp';
    $mech->get_ok('/photo/' . $p->id . '.jpeg');
    $image_file = FixMyStreet->path_to('web/photo/' . $p->id . '.jpeg');
    ok -e $image_file, 'File uploaded to temp';
    my $res = $mech->get('/photo/0.jpeg');
    is $res->code, 404, "got 404";
};

done_testing();
