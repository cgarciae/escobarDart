part of arista;

class AristaImageTarget
{
    @Field () String path;
    @Field() String get url => path != null && path != '' ? localHost + path : '';
    @Field () int version;
    
    AristaImageTarget ();
}

class AristaCloudRecoTarget
{
    @Id() String id;
    @ReferenceId() String imageId;
    @Field() String targetId;
}