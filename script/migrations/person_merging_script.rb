## This script is a very simple script to merge multiple people together.

hbx_id_keep = ""

hbx_id_delete = ""

person_to_keep = Person.where("members.hbx_member_id" => hbx_id_keep).first
person_to_delete = Person.where("members.hbx_member_id" => hbx_id_delete).first

member_to_move = person_to_delete.members.detect {|member| member.hbx_member_id == hbx_id_delete}

person_to_keep.members.push(member_to_move)

person_to_keep.save

person_to_delete.destroy