import MainView from './main-view';
import RoomIndexView from './room/index';
import PlayerShowView from './player/show';
import PrivateRoomNewView from './private-room/new';
import PrivateRoomShowView from './private-room/show';
import RoomShowView from './room/show';

const views = {
  RoomIndexView,
  PlayerShowView,
  PrivateRoomNewView,
  PrivateRoomShowView,
  RoomShowView
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}